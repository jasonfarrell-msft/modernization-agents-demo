# Azure Patterns - Implementation Checklist

Use this checklist when implementing Azure storage, database, and SKU patterns in modernized applications.

---

## Pattern 1: Blob Storage + LRS

### Infrastructure (Bicep/ARM)

- [ ] Storage account resource uses `Microsoft.Storage/storageAccounts`
- [ ] Kind is set to `"BlobStorage"` or `"StorageV2"`
- [ ] Replication is `"Standard_LRS"` (never `GRS`, `GZRS`, or Premium)
- [ ] Access tier is `"Hot"` for frequently accessed data
- [ ] Blob containers are created with appropriate public access: `"Container"` or `"None"` (prefer `"None"`)
- [ ] Managed Identity is assigned `Storage Blob Data Contributor` RBAC role
- [ ] Network rules: default action is `"Deny"` with allow-list for app service/container apps VNet
- [ ] Soft delete and versioning are enabled (optional but recommended for dev)

### .NET Configuration

- [ ] NuGet package `Azure.Storage.Blobs` is installed
- [ ] `BlobContainerClient` is injected via DI (not instantiated inline)
- [ ] Connection uses Managed Identity: `new BlobContainerClient(uri, new DefaultAzureCredential())`
- [ ] Storage account name is externalized to `IConfiguration` (appsettings.json or environment variable)
- [ ] Container name is externalized to configuration
- [ ] No hardcoded storage account keys or connection strings in code
- [ ] Upload/download operations handle Azure SDK exceptions (`Azure.RequestFailedException`)
- [ ] Blobs are tagged with metadata (optional: upload timestamp, user ID, document type)

### Validation

- [ ] Local development uses Azure Storage Emulator or Azurite (not hardcoded account name)
- [ ] Integration tests use a dedicated test storage account (not production)
- [ ] Blob URI is accessible via the app's Managed Identity (RBAC verified)
- [ ] Uploading and downloading a test blob succeeds

---

## Pattern 2: Azure SQL Database with Serverless Compute

### Infrastructure (Bicep/ARM)

- [ ] SQL Server resource uses `Microsoft.Sql/servers`
- [ ] Database resource uses `Microsoft.Sql/servers/databases`
- [ ] Compute tier is `"Serverless"` (never `"Provisioned"` for dev)
- [ ] Edition is `"GeneralPurpose"` (unless data warehouse scenario)
- [ ] `autoPauseDelayInMinutes` is set to `60` (or `true` for automatic)
- [ ] `minCapacity` is `0.5` (half a vCore; typical for dev)
- [ ] `maxCapacity` is `2` (scales up for load)
- [ ] Database collation is `"SQL_Latin1_General_CP1_CI_AS"` (standard for .NET)
- [ ] Server-level firewall rule allows app service/container apps VNET
- [ ] Managed Identity is assigned `SQL Server Contributor` or `SQL DB Contributor` role
- [ ] Azure AD admin is configured (for user/app authentication)

### .NET Configuration

- [ ] Entity Framework Core is used (not raw ADO.NET for new projects)
- [ ] `Microsoft.EntityFrameworkCore.SqlServer` NuGet package is installed
- [ ] Connection string uses Managed Identity: `Authentication=Active Directory Managed Identity`
- [ ] Connection string does NOT contain username, password, or User ID
- [ ] Connection string externalizes server name and database name to configuration
- [ ] `EnableRetryOnFailure()` is enabled in DbContext configuration
- [ ] Connection pooling is enabled: `Pooling=true; Max Pool Size=100`
- [ ] EF Core migrations are used for schema management
- [ ] Async operations are used (`SaveChangesAsync()`, `ToListAsync()`, etc.)

### Database-Level Access

- [ ] Managed Identity user is created: `CREATE USER [<app-mi-name>] FROM EXTERNAL PROVIDER;`
- [ ] Permissions are granted using roles (e.g., `db_datareader`, `db_datawriter`)
- [ ] No SQL-authenticated users are present in the database (except sa for admin only)
- [ ] Row-level security (RLS) is implemented if needed for multi-tenant scenarios

### Validation

- [ ] Local development uses LocalDB or SQL Express (not production server)
- [ ] Connection with Managed Identity succeeds from the app
- [ ] First query after auto-pause (idle 60+ min) succeeds (with retry logic)
- [ ] Database can be paused manually and resumed without breaking the app
- [ ] EF Core migrations apply cleanly to a fresh database

---

## Pattern 3: Development-Tier SKUs

### Compute Selection

- [ ] App Service SKU is `B1` or `B2` (not `S1`, `S2`, `P1`)
- [ ] If using Container Apps: vCPU is `0.25`, memory is `0.5` Gi
- [ ] Auto-scale rules are appropriate for dev load (not aggressive)

### Database SKU

- [ ] SQL Database is Serverless with `minCapacity: 0.5` vCore
- [ ] Auto-pause delay is configured (60 minutes is standard)

### Storage SKU

- [ ] Blob Storage is `Standard_LRS` (never Premium or GRS variants)
- [ ] Access tier is `"Hot"` for active data, `"Cool"` for infrequent access

### Networking SKU

- [ ] Virtual Network is single region (no cross-region peering for dev)
- [ ] Public IPs are used only where necessary
- [ ] No DDoS Protection Premium (not needed for dev)
- [ ] No ExpressRoute or VPN Gateway (not needed for dev)

### Cost Monitoring

- [ ] Azure Cost Analysis is configured to track dev environment spend
- [ ] Budget alert is set (e.g., $50/month for dev)
- [ ] Serverless database auto-pause is verified (check portal: "Paused" state)
- [ ] App Service always-on is disabled (let app shut down during inactivity)

### Validation

- [ ] Monthly cost for dev environment is < $30 (typical with serverless + B1 app)
- [ ] Auto-pause is active (serverless DB shows "Paused" in Azure Portal)
- [ ] Application starts after database auto-resume (retry logic works)

---

## Cross-Pattern Validation

- [ ] All three patterns are applied together (storage + database + SKUs)
- [ ] No hardcoded credentials, keys, or secrets in code
- [ ] Managed Identity is the exclusive authentication method
- [ ] Configuration is externalized (appsettings.json, environment variables, Key Vault)
- [ ] Bicep/IaC includes `environment` parameter to switch dev/prod SKUs
- [ ] Local development can run without accessing Azure (LocalDB, Azurite)
- [ ] Integration tests use dedicated dev Azure resources (not production)
- [ ] Deployment is repeatable and idempotent (IaC, no manual steps)
