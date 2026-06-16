using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LegacyUploadDemo.Azure.Storage;

/// <summary>
/// Demonstrates Azure Blob Storage + LRS pattern.
/// Always use BlobContainerClient with Managed Identity.
/// Never use hardcoded storage account keys.
/// </summary>
public static class BlobStorageConfiguration
{
    /// <summary>
    /// Register BlobContainerClient for dependency injection.
    /// Storage account name and container name are externalized to configuration.
    /// </summary>
    public static IServiceCollection AddBlobStorage(this IServiceCollection services, IConfiguration config)
    {
        var storageAccountName = config["Azure:Storage:AccountName"] 
            ?? throw new InvalidOperationException("Azure:Storage:AccountName is required");
        
        var containerName = config["Azure:Storage:ContainerName"] 
            ?? throw new InvalidOperationException("Azure:Storage:ContainerName is required");
        
        var blobUri = new Uri($"https://{storageAccountName}.blob.core.windows.net/{containerName}");
        
        // Managed Identity authentication - no connection string, no keys
        var blobContainerClient = new BlobContainerClient(blobUri, new Azure.Identity.DefaultAzureCredential());
        
        services.AddSingleton(blobContainerClient);
        
        return services;
    }
}

/// <summary>
/// Example service that uses BlobContainerClient.
/// Demonstrates file upload pattern aligned with azure-patterns.
/// </summary>
public class DocumentUploadService
{
    private readonly BlobContainerClient _blobContainerClient;
    
    public DocumentUploadService(BlobContainerClient blobContainerClient)
    {
        _blobContainerClient = blobContainerClient ?? throw new ArgumentNullException(nameof(blobContainerClient));
    }
    
    /// <summary>
    /// Upload a document to Blob Storage.
    /// Demonstrates:
    /// - Using Managed Identity (implicit in BlobContainerClient)
    /// - Tagging blob with metadata
    /// - Handling Azure SDK exceptions
    /// </summary>
    public async Task<string> UploadDocumentAsync(string fileName, Stream fileStream, string userId)
    {
        try
        {
            var blobClient = _blobContainerClient.GetBlobClient(fileName);
            
            // Upload with metadata tags
            await blobClient.UploadAsync(fileStream, overwrite: true);
            
            // Optionally set metadata
            var metadata = new Dictionary<string, string>
            {
                { "uploadedBy", userId },
                { "uploadedAt", DateTime.UtcNow.ToString("O") }
            };
            await blobClient.SetMetadataAsync(metadata);
            
            return blobClient.Uri.ToString();
        }
        catch (Azure.RequestFailedException ex)
        {
            // Handle Azure-specific exceptions
            throw new InvalidOperationException($"Failed to upload {fileName} to Blob Storage", ex);
        }
    }
    
    /// <summary>
    /// Download a document from Blob Storage.
    /// </summary>
    public async Task<Stream> DownloadDocumentAsync(string fileName)
    {
        try
        {
            var blobClient = _blobContainerClient.GetBlobClient(fileName);
            var download = await blobClient.DownloadAsync();
            return download.Value.Content;
        }
        catch (Azure.RequestFailedException ex)
        {
            throw new InvalidOperationException($"Failed to download {fileName} from Blob Storage", ex);
        }
    }
}
