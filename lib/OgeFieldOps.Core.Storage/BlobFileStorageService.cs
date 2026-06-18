// Pattern: SRP — IFileStorageService handles only blob upload concerns (MODERNIZATION_PATTERNS §5)
// Pattern: Managed Identity — BlobContainerClient via DefaultAzureCredential (MODERNIZATION_PATTERNS §1)
// Pattern: Error Handling — never swallow exceptions; propagate with structured logging (MODERNIZATION_PATTERNS §3)
// Pattern: Observability — structured log events for every storage operation (MODERNIZATION_PATTERNS §4)

using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace OgeFieldOps.Core.Storage;

/// <summary>
/// Uploads files to Azure Blob Storage using Managed Identity.
/// Pattern: Managed Identity — no SAS tokens or account keys; role: Storage Blob Data Contributor.
/// </summary>
public sealed class BlobFileStorageService : IFileStorageService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly BlobStorageOptions _options;
    private readonly ILogger<BlobFileStorageService> _logger;

    public BlobFileStorageService(
        BlobServiceClient blobServiceClient,
        IOptions<BlobStorageOptions> options,
        ILogger<BlobFileStorageService> logger)
    {
        _blobServiceClient = blobServiceClient;
        _options = options.Value;
        _logger = logger;
    }

    public bool IsAllowed(string fileName, long sizeBytes, out FileValidationError? error)
    {
        var ext = Path.GetExtension(fileName).ToLowerInvariant();

        if (!_options.AllowedExtensions.Contains(ext))
        {
            error = new FileValidationError(
                $"File type '{ext}' is not permitted. Allowed: {string.Join(", ", _options.AllowedExtensions)}");
            return false;
        }

        var maxBytes = (long)_options.MaxUploadSizeMb * 1024 * 1024;
        if (sizeBytes > maxBytes)
        {
            error = new FileValidationError(
                $"File size {sizeBytes:N0} bytes exceeds the {_options.MaxUploadSizeMb} MB limit.");
            return false;
        }

        error = null;
        return true;
    }

    public async Task<StoredFileResult> UploadAsync(IFormFile file, string outageTicketNumber, CancellationToken ct = default)
    {
        // Scope blobs under the ticket number for easy discovery
        var safeName = Path.GetFileName(file.FileName);
        var blobName = $"{outageTicketNumber}/{Guid.NewGuid():N}-{safeName}";

        var containerClient = _blobServiceClient.GetBlobContainerClient(_options.ContainerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.None, cancellationToken: ct);

        var blobClient = containerClient.GetBlobClient(blobName);

        // Pattern: Observability — log structured event before and after upload
        _logger.LogInformation(
            "BlobUpload starting. {TicketNumber} {FileName} {SizeBytes}",
            outageTicketNumber, file.FileName, file.Length);

        await using var stream = file.OpenReadStream();
        var uploadResult = await blobClient.UploadAsync(stream, new BlobUploadOptions
        {
            HttpHeaders = new BlobHttpHeaders { ContentType = file.ContentType }
        }, ct);

        _logger.LogInformation(
            "BlobUpload completed. {TicketNumber} {BlobName} {ETag}",
            outageTicketNumber, blobName, uploadResult.Value.ETag);

        return new StoredFileResult(safeName, blobName, file.Length, file.ContentType);
    }
}
