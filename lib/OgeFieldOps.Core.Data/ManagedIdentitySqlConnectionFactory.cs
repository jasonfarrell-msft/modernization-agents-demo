// Pattern: Managed Identity — SqlConnectionFactory uses Entra auth token (MODERNIZATION_PATTERNS §1)
// Pattern: DI — ISqlConnectionFactory interface for testability (MODERNIZATION_PATTERNS §2)

using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace OgeFieldOps.Core.Data;

/// <summary>
/// Opens <see cref="SqlConnection"/> using the connection string from configuration.
/// Connection strings must use Entra authentication (no password).
/// Example: "Server=tcp:yourserver.database.windows.net,1433;Database=OgeFieldOps;
///           Authentication=Active Directory Managed Identity;"
/// Pattern: Managed Identity — no User ID / Password in connection string.
/// </summary>
public sealed class ManagedIdentitySqlConnectionFactory : ISqlConnectionFactory
{
    private readonly string _connectionString;

    public ManagedIdentitySqlConnectionFactory(IOptions<SqlConnectionOptions> options)
        => _connectionString = options.Value.ConnectionString;

    public async Task<SqlConnection> OpenAsync(CancellationToken ct = default)
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(ct);
        return connection;
    }
}
