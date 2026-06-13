# Managed Identity for Azure Access

## Overview

Managed Identity is the Azure-native, **secret-less** way for an application to
authenticate to other Azure services. Azure provisions an identity in Microsoft
Entra ID, attaches it to your compute resource (App Service, Container Apps,
AKS, Functions, VM), and the runtime acquires tokens automatically. **No
passwords, keys, or connection strings live in code or configuration.**

This is the default authentication pattern for every Azure-deployed service in
the eShop modernization. See the security policy in `~/.copilot/copilot-instructions.md`.

## Problem

Traditional auth approaches leak secrets and rotate poorly:

- **Connection strings with embedded keys** end up in `appsettings.json`, env vars, source control, or CI logs.
- **Service principals with client secrets** require rotation, distribution, and a vault to store them — moving the problem, not solving it.
- **Shared access signatures (SAS)** on storage are easy to over-scope and over-grant.
- **API keys** can't be tied to a specific workload identity, so blast radius on leak is huge.

## Solution

Use Managed Identity + Azure RBAC + the unified `Azure.Identity` token credential:

1. Provision a **User-Assigned Managed Identity (UAMI)** (preferred) or System-Assigned (acceptable).
2. Assign **least-privilege RBAC roles** on the target resource (Key Vault, Storage, SQL, Service Bus, Cosmos, etc.).
3. In code, use `DefaultAzureCredential` (or `ManagedIdentityCredential` for prod) — Azure SDK clients accept the credential directly; no keys involved.
4. Wire clients through DI with `Microsoft.Extensions.Azure.AddAzureClients()`.

User-assigned MI is preferred over system-assigned because it survives resource
recreation, supports federated workload identity for AKS/GitHub Actions, and
can be shared across multiple workloads in the same trust boundary.

## Benefits

- **Zero secrets** — nothing to rotate, leak, or store.
- **Least privilege** — RBAC roles scoped to the exact resource.
- **Audit trail** — every token use is attributable to the workload identity.
- **Works locally** — `DefaultAzureCredential` falls back to Azure CLI / VS / VS Code / `azd` developer credentials in dev.
- **Native to Aspire** — `AddAzureClients()` integration is first-class.

## Tradeoffs

- **Local dev needs `az login`** (or VS Code Azure sign-in). One-time cost.
- **First token request has latency** (~tens of ms). Subsequent calls use the cached token.
- **Some legacy services don't support Entra auth** — e.g., Redis Cache requires Azure Managed Redis or ACR with the AAD-enabled tier; older Azure Cache for Redis SKUs may need access keys in Key Vault as a stopgap.
- **RBAC propagation** can take 1–5 minutes after assignment. Plan for it in deploy scripts.

## When to Use

- **Always**, for any Azure resource access from a workload running in Azure.
- For local development, when developers can sign in with `az login` / VS Code.
- For CI/CD, via OIDC federation with `Azure/login@v2` (no client secret).

## When NOT to Use

- Connecting to **non-Azure** services (third-party APIs) — use Key Vault references for those secrets, with MI authenticating to Key Vault.
- Truly local-only utilities that never touch Azure.
- Resources whose data plane does not yet support Entra ID (rare; document the exception and store the key in Key Vault).

## Implementation Steps

1. **Provision a User-Assigned Managed Identity** in Bicep/Terraform.
2. **Attach it** to the compute resource (`identity.userAssignedIdentities`).
3. **Assign RBAC roles** on each target resource (Key Vault, Storage, etc.) — least privilege.
4. **Set `AZURE_CLIENT_ID`** env var on the compute resource so `DefaultAzureCredential` selects the correct UAMI.
5. **Use `Azure.Identity` + `Microsoft.Extensions.Azure`** in code; no keys, no connection strings.
6. **Test locally** with `az login`; the same code path uses Azure CLI credentials in dev.
7. **Validate** with the [checklist](./CHECKLIST.md) before merge.

## Code Example

See [`examples/`](./examples/):

- `Program.cs` — `AddAzureClients()` registration for Key Vault, Storage, Service Bus, Cosmos, SQL.
- `KeyVaultBootstrap.cs` — load Key Vault secrets into `IConfiguration` at startup.
- `SqlWithEntraId.cs` — Azure SQL via access tokens (no connection-string passwords).
- `infra.bicep` — UAMI, RBAC role assignments, and compute attachment.

## Validation Checklist

See [`CHECKLIST.md`](./CHECKLIST.md).

## References

- [Managed identities for Azure resources](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)
- [Azure SDK authentication with `DefaultAzureCredential`](https://learn.microsoft.com/dotnet/azure/sdk/authentication/credential-chains)
- [`Microsoft.Extensions.Azure`](https://learn.microsoft.com/dotnet/azure/sdk/dependency-injection)
- [Azure RBAC built-in roles](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Workload identity federation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation)
- [Azure Well-Architected: Identity and access management](https://learn.microsoft.com/azure/well-architected/security/identity-access)
