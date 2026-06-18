// Pattern: SRP — IFileStorageService handles only blob upload concerns (MODERNIZATION_PATTERNS §5)

using Microsoft.AspNetCore.Http;

namespace OgeFieldOps.Core.Storage;

public sealed record StoredFileResult(string FileName, string BlobPath, long SizeBytes, string ContentType);
public sealed record FileValidationError(string Message);

/// <summary>Validates and uploads files to cloud storage.</summary>
public interface IFileStorageService
{
    bool IsAllowed(string fileName, long sizeBytes, out FileValidationError? error);
    Task<StoredFileResult> UploadAsync(IFormFile file, string outageTicketNumber, CancellationToken ct = default);
}
