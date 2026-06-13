// Hydrate IConfiguration from Key Vault at startup using Managed Identity.
// Once loaded, secrets are accessible via builder.Configuration["MySecret"]
// or bound to typed options — exactly like any other config provider.
//
// NuGet: Azure.Extensions.AspNetCore.Configuration.Secrets

using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.Extensions.Configuration;

namespace Patterns.ManagedIdentity.Examples;

public static class KeyVaultBootstrap
{
    public static IConfigurationBuilder AddEShopKeyVault(
        this IConfigurationBuilder configuration,
        string keyVaultUri,
        string? userAssignedClientId = null)
    {
        var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            ManagedIdentityClientId = userAssignedClientId,
        });

        var client = new SecretClient(new Uri(keyVaultUri), credential);

        // KeyVaultSecretManager controls which secrets are loaded and how the names
        // are flattened into config keys (e.g., "Database--ConnectionString" -> "Database:ConnectionString").
        configuration.AddAzureKeyVault(client, new KeyVaultSecretManager());

        return configuration;
    }
}
