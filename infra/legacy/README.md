# Legacy VM deployment scaffolding

This folder contains reproducible infrastructure and guest configuration scripts for the legacy demo VM (`vm-legacy-swc`) in resource group `rg-modernization-swc-mx01` (region `swedencentral`).

## What it deploys
- Windows VM with public IP + NSG rules for RDP/HTTP/HTTPS.
- Optional Custom Script Extension hook.
- Guest-side scripts for SQL Express install, DB provisioning, IIS/ASP.NET 4.x setup, GitHub runner registration, and optional SSL.

## Prerequisites
- Azure CLI logged in.
- Bicep CLI available (`bicep`).
- Secrets set as environment variables (never hardcode):

```bash
export VM_ADMIN_PASSWORD='<vm-admin-password>'
export SQL_SA_PASSWORD='<sql-sa-password>'
export OGE_APP_PASSWORD='<oge_app-password>'
export GITHUB_RUNNER_REGISTRATION_TOKEN='<short-lived-runner-registration-token>'
# Optional overrides:
export GITHUB_RUNNER_URL='https://github.com/jasonfarrell-msft/modernization-agents-demo'
export GITHUB_RUNNER_NAME='vm-legacy-swc'
export GITHUB_RUNNER_LABELS='self-hosted,Windows,X64,iis-deploy'
```

## Ordered rebuild sequence (zero manual steps)

### Single command from your workstation

Run the central script (`deploy.sh`) with `--full-setup`:

```bash
./deploy.sh \
  --resource-group rg-modernization-swc-mx01 \
  --location swedencentral \
  --full-setup \
  --contact-email ops@yourorg.com
```

Execution order is:
1. Bicep deploy (`main.bicep` + `main.bicepparam`)
2. `install-sql-express.ps1` (SQL Express unattended install, instance `SQLEXPRESS`)
3. `provision-legacy-db.ps1` (creates DB/login/user and runs `Schema.sql` then `Seed.sql` via `System.Data.SqlClient` + `GO` splitting)
4. `install-iis.ps1` (IIS + ASP.NET 4.x features required by MVC5)
5. `register-github-runner.ps1` (labels: `self-hosted,Windows,X64,iis-deploy`, installed as Windows service)
6. `install-ssl.ps1` (optional when `--contact-email` is provided)

### Guest-side entry point (inside VM)

If you prefer running entirely from the VM, use:

```powershell
.\configure-legacy-vm.ps1 `
  -SqlSaPassword $env:SQL_SA_PASSWORD `
  -OgeAppPassword $env:OGE_APP_PASSWORD `
  -RunnerUrl $env:GITHUB_RUNNER_URL `
  -RunnerRegistrationToken $env:GITHUB_RUNNER_REGISTRATION_TOKEN `
  -RunnerLabels 'self-hosted,Windows,X64,iis-deploy' `
  -ContactEmail $env:LETSENCRYPT_CONTACT_EMAIL
```

## Script details

### `install-sql-express.ps1`
- Uses unattended install via generated `ConfigurationFile.ini`.
- Installs `SQLEXPRESS` in mixed mode (`sa` password passed by parameter/env var).
- Idempotent: skips install if service `MSSQL$SQLEXPRESS` already exists.

### `provision-legacy-db.ps1`
- Ensures database `OgeFieldOps` exists.
- Ensures SQL login/user `oge_app` exists and is in `db_owner`.
- Executes schema + seed batches using `System.Data.SqlClient` (no `sqlcmd` dependency).
- Splits SQL scripts on `GO` lines.
- Idempotent/re-runnable: object creation uses existence guards; schema/seed scripts reset and repopulate data safely on rerun.

### `install-iis.ps1`
Installs IIS plus ASP.NET 4.x support required for classic MVC5:
- `Web-Server`
- `Web-Mgmt-Tools`
- `Web-Net-Ext45`
- `Web-Asp-Net45`
- `Web-ISAPI-Ext`
- `Web-ISAPI-Filter`
- `NET-Framework-45-ASPNET`

### `register-github-runner.ps1`
- Registers runner against `GITHUB_RUNNER_URL`.
- Uses required labels: `self-hosted,Windows,X64,iis-deploy`.
- Installs as a Windows service and starts it.
- Idempotent: if an existing `actions.runner.*` service is already present, script skips re-registration and ensures service is running.

### `install-ssl.ps1`
- Obtains Let's Encrypt certificate via win-acme.
- Binds HTTPS and configures HTTP→HTTPS redirect.
- Idempotent and safe to rerun.

## Runner token notes
`GITHUB_RUNNER_REGISTRATION_TOKEN` is short-lived. Generate a fresh token before rebuild and pass it as an environment variable. Do not commit tokens or PATs.

## Notes
- Existing NSG rules already allow 80/443/3389.
- `main.bicepparam` reads `VM_ADMIN_PASSWORD` from environment.
- For full reproducibility, use `--full-setup` so all post-deploy guest steps execute in order.
