// Pattern: DI / Options — typed configuration for blob storage (MODERNIZATION_PATTERNS §2)
// Pattern: Managed Identity — AccountUri only; no connection strings or SAS keys

namespace OgeFieldOps.Core.Storage;

/// <summary>
/// Blob Storage options. Bind to the "Storage" config section.
/// The account URI is the only value needed; Managed Identity handles auth.
/// </summary>
public sealed class BlobStorageOptions
{
    public string ContainerName { get; set; } = "field-documents";

    public IReadOnlyList<string> AllowedExtensions { get; set; } =
        new[] { ".pdf", ".csv", ".txt", ".jpg", ".jpeg", ".png", ".xlsx" };

    public int MaxUploadSizeMb { get; set; } = 25;
}
