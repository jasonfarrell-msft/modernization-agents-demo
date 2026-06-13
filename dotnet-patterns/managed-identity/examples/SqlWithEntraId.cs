// Azure SQL Database with Managed Identity — no password in connection string.
//
// Required setup:
//   1. CREATE USER [<uami-name>] FROM EXTERNAL PROVIDER
//   2. ALTER ROLE db_datareader ADD MEMBER [<uami-name>]
//      ALTER ROLE db_datawriter ADD MEMBER [<uami-name>]  -- as needed
//   3. Connection string: Server=tcp:<srv>.database.windows.net;Database=<db>;Authentication=Active Directory Default;
//
// NuGet: Microsoft.Data.SqlClient (5.x+) handles "Authentication=Active Directory Default" natively.

using Azure.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Patterns.ManagedIdentity.Examples;

public static class SqlRegistration
{
    // Option A (preferred): SqlClient handles tokens via the connection string.
    public static IServiceCollection AddCatalogDbContextViaConnectionString(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Connection string contains NO password — only server + database + Authentication mode.
        var connectionString = configuration.GetConnectionString("CatalogDb")
            ?? throw new InvalidOperationException("CatalogDb connection string missing");

        services.AddDbContext<CatalogDbContext>(opts => opts.UseSqlServer(connectionString));
        return services;
    }

    // Option B: explicit token acquisition (for older SqlClient or custom scenarios).
    public static IServiceCollection AddCatalogDbContextViaToken(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<CatalogDbContext>((sp, opts) =>
        {
            var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                ManagedIdentityClientId = configuration["Azure:ClientId"],
            });

            var connectionString = configuration.GetConnectionString("CatalogDb")!;
            var connection = new SqlConnection(connectionString);

            // Acquire token for Azure SQL scope.
            var token = credential.GetToken(
                new Azure.Core.TokenRequestContext(["https://database.windows.net/.default"]),
                default);
            connection.AccessToken = token.Token;

            opts.UseSqlServer(connection);
        });
        return services;
    }
}

internal sealed class CatalogDbContext(DbContextOptions<CatalogDbContext> options) : DbContext(options);
