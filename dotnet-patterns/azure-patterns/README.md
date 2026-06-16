# Azure Patterns

Customer-standardized Azure service selection and SKU guidance for development environments.

## Overview

These patterns enforce consistent Azure resource choices across modernized applications:
- **Storage**: Always use Azure Blob Storage with Locally Redundant Storage (LRS)
- **Database**: Always use Azure SQL Database with Serverless compute tier
- **Compute & Services**: Always select development-tier SKUs appropriate for dev environments

This standardization reduces decision overhead, optimizes cost for development workloads, and ensures consistent infrastructure patterns.

---

## Pattern 1: Blob Storage + Locally Redundant Storage (LRS)

### When to Apply
When modernizing file upload, document storage, or any object storage requirements.

### Rationale
- **Blob Storage**: Azure's native object storage service; cost-effective, scalable, and integrates with .NET Azure SDK
- **LRS**: Locally Redundant Storage provides redundancy within a single data center at lowest cost; appropriate for dev environments and non-critical data

### Implementation Requirements

1. **Bicep/ARM Template**
   - Use `Microsoft.Storage/storageAccounts` resource type
   - Set `kind: "BlobStorage"` or `"StorageV2"` (StorageV2 if multi-purpose)
   - Set replication: `"Standard_LRS"`
   - Set access tier: `"Hot"` for frequently accessed data, `"Cool"` for archive scenarios

2. **.NET Configuration**
   - Use `Azure.Storage.Blobs.BlobContainerClient` from `Azure.Storage.Blobs` NuGet package
   - Inject `BlobContainerClient` via dependency injection
   - Use Managed Identity for authentication (not connection strings)
   - Externalize storage account name and container name to configuration

3. **Managed Identity**
   - Assign `Storage Blob Data Contributor` RBAC role to the app's Managed Identity
   - Grant minimum required permissions (not Storage Account Contributor)

### Example Use Cases
- File uploads (legacy-upload-demo: document storage)
- Temporary blob storage for processing
- Audit log archival

---

## Pattern 2: Azure SQL Database with Serverless Compute

### When to Apply
When replacing on-premises SQL Server or any relational database requirement.

### Rationale
- **Azure SQL**: Managed relational database; eliminates infrastructure overhead, provides automated backups, and integrates seamlessly with .NET
- **Serverless Compute**: Auto-scales based on workload; cost-effective for dev/test environments; automatically pauses during inactivity

### Implementation Requirements

1. **Bicep/ARM Template**
   - Use `Microsoft.Sql/servers` resource type for the server
   - Use `Microsoft.Sql/servers/databases` resource type for the database
   - Set compute tier: `"Serverless"`
   - Set edition: `"GeneralPurpose"` (recommended for most workloads)
   - Set `autoPauseDelayInMinutes`: 60 (pause after 60 min inactivity; adjust for dev vs. staging)
   - Set `minCapacity`: 0.5 (half a vCore minimum; typical for dev workloads)

2. **.NET Configuration**
   - Use `SqlConnection` from `System.Data.SqlClient` or `Microsoft.Data.SqlClient` (newer)
   - Use Entity Framework Core with `UseSqlServer()` fluent API
   - Use Managed Identity authentication: set `Authentication=Active Directory Managed Identity` in connection string
   - Externalize server name and database name to configuration
   - Do NOT use SQL authentication (username/password); use Managed Identity only

3. **Managed Identity**
   - Assign `SQL Server Contributor` or `SQL DB Contributor` RBAC role to the app's Managed Identity
   - Grant database-level permissions via SQL (`CREATE USER [<MI-name>] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [<MI-name>];`)

4. **Connection Resilience**
   - Enable connection pooling: `Pooling=true; Max Pool Size=100`
   - Add retry logic: Entity Framework Core `EnableRetryOnFailure()` for transient fault handling
   - Use exponential backoff for serverless auto-pause recovery

### Example Use Cases
- Application data persistence (legacy-upload-demo: outages, documents, metadata)
- User/authentication data
- Audit trail storage

---

## Pattern 3: Development-Tier SKUs

### When to Apply
All resource deployments targeting development or test environments.

### Rationale
- Reduces operational costs for non-production workloads
- Prevents over-provisioning during development phases
- Provides adequate performance for development and testing scenarios
- Can be upgraded to production SKUs later without architecture changes

### Development-Tier SKU Guidance

#### Compute & App Services
- **Azure App Service**: `B1` (Shared) or `B2` (Basic)
  - Avoid: `S1`, `S2`, `P1` (production-tier)
  - 1–2 vCPU, 1–3.5 GB RAM is sufficient for dev

- **Azure Container Apps**: `0.25` vCPU, `0.5` Gi memory
  - Appropriate for dev workloads
  - Auto-scales to `2` vCPU / `4` Gi on demand

#### Database
- **Azure SQL**: Serverless `GeneralPurpose`, min `0.5` vCore, max `2` vCore
  - Auto-pauses after inactivity
  - Typical dev cost: $5–15/month when paused

#### Storage
- **Blob Storage**: `Standard_LRS` (no Premium tier for dev)
- **Data Transfer**: Minimize egress; assume dev/test traffic is low

#### Networking
- **Virtual Network**: Single subnet; no ExpressRoute or complex peering
- **Public IP**: Use where needed; no DDoS Premium
- **Load Balancer**: Use `Basic` SKU (not `Standard` for dev)

### Implementation Requirements

1. **Bicep/ARM Parameters**
   ```bicep
   param environment string = 'dev'  // 'dev' | 'prod'
   param appServiceSku string = environment == 'dev' ? 'B1' : 'S1'
   param databaseMinCapacity int = environment == 'dev' ? 1 : 2  // vCores
   ```

2. **.NET Configuration**
   - No code changes required
   - Use environment-based configuration (`appsettings.Development.json`)
   - Externalize resource names and SKU choices

3. **Cost Monitoring**
   - Use Azure Cost Analysis to track dev environment spend
   - Alert on unexpected overages (e.g., unpaused serverless database)
   - Set monthly budgets per environment

---

## Summary Table: Approved Azure Services for Modernization

| Category | Service | Tier/SKU | Notes |
|----------|---------|----------|-------|
| **Storage** | Azure Blob Storage | Standard_LRS | Always LRS for dev; use Hot access tier for frequent access |
| **Database** | Azure SQL | Serverless, GeneralPurpose, 0.5–2 vCore min/max | Auto-pause enabled; 60 min inactivity |
| **Compute** | App Service OR Container Apps | B1/B2 (App) or 0.25 vCPU (Containers) | Choose based on containerization preference |
| **Authentication** | Entra ID (Managed Identity) | Built-in | No SQL auth, no hardcoded secrets |
| **Messaging** | Event Grid or Service Bus | Standard tier | For async patterns; Standard is cost-effective for dev |
| **Logging** | Application Insights | Pay-as-you-go | Included with App Service; 5 GB/month free tier |
| **Networking** | Virtual Network | Single region, basic NSGs | No ExpressRoute or Traffic Manager for dev |

---

## Validation Checklist

Before deploying, confirm:
- [ ] Blob Storage is `Standard_LRS` (not Premium, not GRS/GZRS)
- [ ] SQL Database is `Serverless` compute with `autoPauseDelayInMinutes: 60`
- [ ] SQL min capacity is `0.5` vCore for dev
- [ ] All SKUs selected match development tier guidance (B1, 0.25 vCPU, etc.)
- [ ] Managed Identity is used for all service authentication
- [ ] No connection strings or SQL auth in code
- [ ] Resource names are externalized to configuration
- [ ] Bicep/IaC includes `environment` parameter for SKU selection
- [ ] Cost tracking is enabled (Azure Cost Analysis or budget alerts)
