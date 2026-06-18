// Pattern: DI / Options — typed configuration for infrastructure health checks (MODERNIZATION_PATTERNS §2)

namespace OgeFieldOps.Core.Infrastructure;

/// <summary>
/// Blob Storage health check options. Bind to the "Storage" config section.
/// </summary>
public sealed class BlobHealthCheckOptions
{
    public string ContainerName { get; set; } = "field-documents";
}
