param()

$ErrorActionPreference = 'Stop'

Write-Host 'Installing IIS features...'
Install-WindowsFeature Web-Server, Web-Mgmt-Tools -IncludeAllSubFeature -IncludeManagementTools

$siteRoot = 'C:\inetpub\wwwroot'
New-Item -ItemType Directory -Force -Path $siteRoot | Out-Null

@'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Legacy Demo VM</title>
</head>
<body style="font-family: Segoe UI, Arial, sans-serif; margin: 2rem; color: #1f2937;">
  <h1>Legacy demo VM is running</h1>
  <p>This endpoint was brought up by the Azure custom script extension for the modernization demo.</p>
  <p>Use this public URL to verify the VM runtime path is live.</p>
</body>
</html>
'@ | Set-Content -Path (Join-Path $siteRoot 'index.html') -Encoding UTF8

Write-Host 'Starting IIS...'
Start-Service W3SVC

Write-Host 'Restarting IIS...'
iisreset /restart

Write-Host 'IIS setup completed.'
