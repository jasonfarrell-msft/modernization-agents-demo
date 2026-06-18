// Pattern: DI / Options — typed configuration for database connection (MODERNIZATION_PATTERNS §2)
// Pattern: Managed Identity — connection string uses Entra auth; no User ID / Password

namespace OgeFieldOps.Core.Data;

/// <summary>
/// Database connection options. Bind to the "Database" config section.
/// The connection string must use Entra authentication — no User ID / Password.
/// Example: "Server=tcp:yourserver.database.windows.net,1433;Database=OgeFieldOps;
///           Authentication=Active Directory Managed Identity;"
/// </summary>
public sealed class SqlConnectionOptions
{
    public string ConnectionString { get; set; } = string.Empty;
}
