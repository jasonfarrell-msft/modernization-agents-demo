// Pattern: SRP — health checks isolated per infrastructure dependency (MODERNIZATION_PATTERNS §5)
// Pattern: Managed Identity — no credentials in health checks (MODERNIZATION_PATTERNS §1)

using Azure.Storage.Blobs;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using OgeFieldOps.Core.Data;

namespace OgeFieldOps.Core.Infrastructure;

/// <summary>Health check: can we reach the blob container?</summary>
public sealed class BlobStorageHealthCheck : IHealthCheck
{
    private readonly BlobServiceClient _client;
    private readonly string _containerName;

    public BlobStorageHealthCheck(BlobServiceClient client, IOptions<BlobHealthCheckOptions> options)
    {
        _client = client;
        _containerName = options.Value.ContainerName;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct)
    {
        try
        {
            var container = _client.GetBlobContainerClient(_containerName);
            await container.GetPropertiesAsync(cancellationToken: ct);
            return HealthCheckResult.Healthy();
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Cannot reach blob container", ex);
        }
    }
}

/// <summary>Health check: can we open a SQL connection?</summary>
public sealed class SqlHealthCheck : IHealthCheck
{
    private readonly ISqlConnectionFactory _db;

    public SqlHealthCheck(ISqlConnectionFactory db) => _db = db;

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct)
    {
        try
        {
            await using var conn = await _db.OpenAsync(ct);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = "SELECT 1";
            await cmd.ExecuteScalarAsync(ct);
            return HealthCheckResult.Healthy();
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Cannot reach SQL database", ex);
        }
    }
}
