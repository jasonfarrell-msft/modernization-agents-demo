// Composition root: register Azure SDK clients with Managed Identity.
// Zero secrets, zero connection strings with keys.
//
// NuGet:
//   Azure.Identity
//   Microsoft.Extensions.Azure
//   Azure.Security.KeyVault.Secrets
//   Azure.Storage.Blobs
//   Azure.Messaging.ServiceBus
//   Microsoft.Azure.Cosmos

using Azure.Identity;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

// Build a single TokenCredential for the whole app.
// In Azure: uses the User-Assigned MI selected by AZURE_CLIENT_ID.
// Locally:  falls back to Azure CLI / VS / VS Code developer credentials.
var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
{
    ManagedIdentityClientId = builder.Configuration["Azure:ClientId"], // UAMI client id (env: AZURE_CLIENT_ID)
    ExcludeInteractiveBrowserCredential = true,
    ExcludeVisualStudioCodeCredential = builder.Environment.IsProduction(),
    ExcludeAzureCliCredential = builder.Environment.IsProduction(),
});

// 1. Hydrate IConfiguration from Key Vault BEFORE registering services that consume options.
//    Requires "Key Vault Secrets User" RBAC role on the vault.
var keyVaultUri = builder.Configuration["Azure:KeyVaultUri"]; // e.g., https://kv-eshop-prod.vault.azure.net/
if (!string.IsNullOrWhiteSpace(keyVaultUri))
{
    builder.Configuration.AddAzureKeyVault(new Uri(keyVaultUri), credential);
}

// 2. Register Azure SDK clients via Microsoft.Extensions.Azure.
//    Each client picks up the shared credential and is injectable through DI.
builder.Services.AddAzureClients(clients =>
{
    clients.UseCredential(credential);

    // Key Vault — for runtime secret reads (rare; prefer Configuration binding above).
    clients.AddSecretClient(new Uri(builder.Configuration["Azure:KeyVaultUri"]!));

    // Storage — Blob with the data-plane endpoint, no account key.
    // Required RBAC: "Storage Blob Data Reader" / "...Contributor" on the storage account or container.
    clients.AddBlobServiceClient(new Uri(builder.Configuration["Azure:Storage:BlobUri"]!));

    // Service Bus — fully qualified namespace, not a connection string.
    // Required RBAC: "Azure Service Bus Data Sender" / "...Receiver" on the namespace or entity.
    clients.AddServiceBusClientWithNamespace(builder.Configuration["Azure:ServiceBus:Namespace"]!);
});

// 3. Cosmos DB — use the Cosmos SDK directly with the same credential.
//    Required RBAC: "Cosmos DB Built-in Data Contributor" (data-plane role, assigned via az cli).
builder.Services.AddSingleton(sp => new Microsoft.Azure.Cosmos.CosmosClient(
    accountEndpoint: builder.Configuration["Azure:Cosmos:Endpoint"]!,
    tokenCredential: credential));

var app = builder.Build();
app.Run();
