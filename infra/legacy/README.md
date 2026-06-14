# Legacy VM deployment scaffolding

This folder contains Azure Bicep for a legacy demo VM in resource group `rg-modernization-swc-mx01` in Sweden Central.

## What it deploys
- Windows VM with a public IP and NSG rules for RDP, HTTP, and HTTPS.
- Optional Custom Script Extension hook for IIS/legacy app setup.

## Suggested deployment flow
For the demo, use the Bash/Azure CLI script in this folder:

1. Run the deployment script:
   ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral
2. If you want the VM to self-configure IIS during deployment, pass a public script URI:
   ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral --custom-script-uri https://example.com/install-iis.ps1

The script uses the native Bicep parameter file under the hood and also runs the guest-side IIS setup script on the VM, so the demo path is self-contained.

## Notes
- `main.bicepparam` is the preferred deployment input. Generated JSON artifacts such as `main.parameters.json` and `main.json` are not required for the standard flow.

## Notes
- The VM is intentionally public for the legacy demo path.
- If SSL is required, place a certificate on the VM (IIS or reverse proxy) and update the NSG/URL accordingly.
- For a production-ready Azure version of this sample, prefer Azure App Service or Azure VM + Azure Files / Blob Storage rather than local disk.
