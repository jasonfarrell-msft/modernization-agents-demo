// Pattern: DI — ISqlConnectionFactory interface for testability (MODERNIZATION_PATTERNS §2)

using Microsoft.Data.SqlClient;

namespace OgeFieldOps.Core.Data;

/// <summary>Opens an authenticated <see cref="SqlConnection"/>.</summary>
public interface ISqlConnectionFactory
{
    Task<SqlConnection> OpenAsync(CancellationToken ct = default);
}
