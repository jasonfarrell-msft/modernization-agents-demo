# Managed Identity — Validation Checklist

## Identity provisioning

- [ ] User-Assigned Managed Identity (UAMI) provisioned in Bicep/Terraform (preferred over system-assigned)
- [ ] UAMI attached to every compute resource that needs Azure access (App Service, Container Apps, AKS pod, Function App, etc.)
- [ ] `AZURE_CLIENT_ID` env var set on the compute resource so `DefaultAzureCredential` picks the right UAMI
- [ ] One UAMI per workload trust boundary — not a shared "god" identity

## RBAC

- [ ] Built-in roles preferred over custom roles
- [ ] Role assigned at the **narrowest scope** that works (resource > resource group > subscription)
- [ ] Least privilege verified: no `Owner`, `Contributor`, or `User Access Administrator` unless justified in code review
- [ ] Data-plane roles used where they exist (e.g., `Storage Blob Data Reader` not `Reader`)
- [ ] Role assignments declared in IaC, not portal-clicked

## Code

- [ ] No connection strings with keys, account keys, SAS, or passwords in `appsettings.json`, env vars, or code
- [ ] All Azure SDK clients constructed with `TokenCredential` (typically `DefaultAzureCredential` or `ManagedIdentityCredential`)
- [ ] Clients registered through `Microsoft.Extensions.Azure.AddAzureClients()` and resolved via DI
- [ ] `DefaultAzureCredential` configured with `ManagedIdentityClientId` set to the UAMI's client ID
- [ ] No `new HttpClient()` calling Azure ARM directly — use the SDKs
- [ ] Key Vault used for any unavoidable third-party secrets, fronted by MI auth

## Configuration

- [ ] Key Vault secrets loaded into `IConfiguration` at startup via `Azure.Extensions.AspNetCore.Configuration.Secrets` (with MI)
- [ ] No secrets in source control, GitHub Actions logs, or container images
- [ ] CI/CD uses OIDC federation (`azure/login@v2` with `client-id` + `tenant-id` + `subscription-id`, no `client-secret`)

## Networking

- [ ] Private endpoints used for Key Vault, Storage, SQL, Cosmos, Service Bus where data sensitivity warrants it
- [ ] Resource firewalls deny public network access where private endpoints are in place
- [ ] HTTPS/TLS enforced; no plaintext data plane

## Operations

- [ ] Token failures logged with sufficient context (UAMI client ID, target resource, scope)
- [ ] Health checks include a token acquisition probe for critical dependencies
- [ ] Deployment scripts wait for RBAC propagation (or retry token-dependent steps)
- [ ] Local dev path documented (`az login` or VS Code Azure sign-in) and works for new contributors
