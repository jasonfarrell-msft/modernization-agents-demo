# Legacy VM deployment scaffolding

This folder contains Azure Bicep for a legacy demo VM in resource group `rg-modernization-swc-mx01` in Sweden Central.

## What it deploys
- Windows VM with a public IP and NSG rules for RDP, HTTP, and HTTPS.
- Optional Custom Script Extension hook for IIS/legacy app setup.

## Suggested deployment flow
For the demo, use the Bash/Azure CLI script in this folder:

1. Run the deployment script:
   ```
   ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral
   ```
2. If you want the VM to self-configure IIS during deployment, pass a public script URI:
   ```
   ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral --custom-script-uri https://example.com/install-iis.ps1
   ```

The script uses the native Bicep parameter file under the hood and also runs the guest-side IIS setup script on the VM, so the demo path is self-contained.

## TLS / HTTPS setup

The site is served over **HTTPS (port 443)** using a free, trusted, auto-renewing
[Let's Encrypt](https://letsencrypt.org/) certificate obtained via
[win-acme](https://www.win-acme.com/).

### How to enable TLS on the VM

Run the following command in an **elevated PowerShell** session on the VM:

```powershell
.\install-ssl.ps1 -ContactEmail ops@yourorg.com
```

The script is idempotent — it is safe to run again after an environment rebuild.

#### What the script does

| Step | Action |
|------|--------|
| 1 | Installs the **IIS URL Rewrite 2.1** module (if not already present). |
| 2 | Downloads **win-acme** to `C:\tools\wacs\`. |
| 3 | Runs win-acme in unattended mode: obtains a Let's Encrypt cert via HTTP-01 challenge, binds it to IIS on **port 443**, and registers a **Windows Scheduled Task** for automatic renewal every 60 days. |
| 4 | Injects a URL Rewrite rule into the site's `web.config` so all HTTP requests receive a **301 Permanent redirect** to HTTPS. |

#### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Domain` | `vm-legacy-swc.swedencentral.cloudapp.azure.com` | Public FQDN of the VM; must resolve to this host at issuance time. |
| `-SiteName` | `OgeFieldOps` | IIS website name (falls back to `Default Web Site` if not found). |
| `-ContactEmail` | *(required)* | E-mail address for the Let's Encrypt ACME account. |
| `-WacsVersion` | `2.2.9.1701` | win-acme release version to download. |
| `-WacsDir` | `C:\tools\wacs` | Local directory for win-acme binaries. |

### Port 80 decision

**Port 80 is kept open** (NSG rule `AllowHTTP`).

The ACME HTTP-01 challenge requires port 80 to be reachable from the internet at
every renewal attempt. Closing port 80 at the NSG would silently break automatic
renewal every 60 days.

If you prefer to close port 80 after initial issuance:
1. Reconfigure win-acme to use **TLS-ALPN-01** validation (no port 80 needed).
2. Update the NSG rule `AllowHTTP` to **Deny** in `main.bicep`.
3. Document the change so the next engineer knows why port 80 is closed.

### Auto-renewal

win-acme registers a **Windows Scheduled Task** (`win-acme renew (acme-v02.api.letsencrypt.org)`)
that runs daily and renews any certificate with fewer than 55 days remaining.
No manual intervention is required.

To verify the scheduled task exists on the VM:
```powershell
Get-ScheduledTask | Where-Object TaskName -like '*win-acme*'
```

To test renewal without waiting:
```powershell
& 'C:\tools\wacs\wacs.exe' --renew --force
```

## Notes
- `main.bicepparam` is the preferred deployment input. Generated JSON artifacts such as `main.parameters.json` and `main.json` are not required for the standard flow.
- The VM is intentionally public for the legacy demo path.
- For a production-ready Azure version of this sample, prefer Azure App Service or Azure VM + Azure Files / Blob Storage rather than local disk.
