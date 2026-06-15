#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Obtain a Let's Encrypt TLS certificate for the IIS legacy site and force
    all HTTP traffic to redirect to HTTPS.

.DESCRIPTION
    Idempotent guest-side script that:
      1. Installs the IIS URL Rewrite 2.1 module (if not already present).
      2. Downloads win-acme and uses it to:
           - Obtain a free, trusted Let's Encrypt certificate via HTTP-01 challenge.
           - Bind the certificate to the IIS site on port 443.
           - Register a Windows Scheduled Task for automatic renewal.
      3. Injects an IIS URL Rewrite rule into the site's web.config so every
         HTTP request receives a 301 Permanent redirect to HTTPS.

    PORT 80 DECISION
    ----------------
    Port 80 is intentionally kept open after issuance.  The ACME HTTP-01
    challenge requires port 80 to be reachable at every renewal (default:
    every 60 days).  Closing port 80 at the NSG would break unattended
    renewal; if you prefer to close it, switch win-acme to TLS-ALPN-01
    validation and update the NSG rule 'AllowHTTP' to Deny.

.PARAMETER Domain
    Public FQDN of the VM.  Must resolve to this host at run time so the
    ACME HTTP-01 challenge can be completed.

.PARAMETER SiteName
    IIS website name.  Defaults to 'OgeFieldOps'; falls back to
    'Default Web Site' if that site does not exist.

.PARAMETER ContactEmail
    E-mail address registered with Let's Encrypt for expiry notifications
    and ACME account recovery.  Required.

.PARAMETER WacsVersion
    win-acme release version to download (without a leading 'v').
    Update this value when a newer stable release is available.

.PARAMETER WacsDir
    Local directory where win-acme binaries are extracted.

.EXAMPLE
    # Run on the VM (elevated PowerShell):
    .\install-ssl.ps1 -ContactEmail ops@example.com

.EXAMPLE
    # Override the target domain (useful for a renamed VM):
    .\install-ssl.ps1 -Domain my-vm.region.cloudapp.azure.com -ContactEmail ops@example.com
#>
param(
    [string]$Domain       = 'vm-legacy-swc.swedencentral.cloudapp.azure.com',
    [string]$SiteName     = 'OgeFieldOps',
    [Parameter(Mandatory)]
    [string]$ContactEmail,
    [string]$WacsVersion  = '2.2.9.1701',
    [string]$WacsDir      = 'C:\tools\wacs'
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# 1. Import WebAdministration and resolve the IIS site
# ---------------------------------------------------------------------------
Write-Step 'Resolving IIS site...'
Import-Module WebAdministration -ErrorAction Stop

$site = Get-WebSite -Name $SiteName -ErrorAction SilentlyContinue
if (-not $site) {
    Write-Host "  Site '$SiteName' not found; falling back to 'Default Web Site'." -ForegroundColor Yellow
    $SiteName = 'Default Web Site'
    $site      = Get-WebSite -Name $SiteName -ErrorAction Stop
}

$siteId       = [int]$site.id
$sitePhysPath = [System.Environment]::ExpandEnvironmentVariables($site.physicalPath)
Write-Host "  Site : '$SiteName'  (ID $siteId)"
Write-Host "  Root : $sitePhysPath"

# ---------------------------------------------------------------------------
# 2. Ensure IIS URL Rewrite 2.1 module is installed
# ---------------------------------------------------------------------------
Write-Step 'Checking IIS URL Rewrite module...'
$rewriteDll = Join-Path $env:SystemRoot 'System32\inetsrv\rewrite.dll'
if (-not (Test-Path $rewriteDll)) {
    $msiUrl  = 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi'
    $msiPath = Join-Path $env:TEMP 'rewrite_amd64_en-US.msi'
    Write-Host '  Downloading IIS URL Rewrite 2.1...'
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
    Write-Host '  Installing IIS URL Rewrite 2.1...'
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
    Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
    Write-Host '  URL Rewrite installed.'
} else {
    Write-Host '  URL Rewrite already installed - skipped.'
}

# ---------------------------------------------------------------------------
# 3. Download win-acme if not already present
# ---------------------------------------------------------------------------
Write-Step "Checking win-acme v$WacsVersion..."
$wacsExe = Join-Path $WacsDir 'wacs.exe'
if (-not (Test-Path $wacsExe)) {
    $zipUrl  = "https://github.com/win-acme/win-acme/releases/download/v$WacsVersion/win-acme.v$WacsVersion.x64.pluggable.zip"
    $zipPath = Join-Path $env:TEMP 'wacs.zip'
    Write-Host "  Downloading win-acme from:`n    $zipUrl"
    New-Item -ItemType Directory -Force -Path $WacsDir | Out-Null
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $WacsDir -Force
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "  win-acme extracted to: $WacsDir"
} else {
    Write-Host "  win-acme already present at: $wacsExe - skipped download."
}

# ---------------------------------------------------------------------------
# 4. Obtain / renew certificate and create HTTPS binding via win-acme
# ---------------------------------------------------------------------------
Write-Step "Obtaining Let's Encrypt certificate for '$Domain'..."
Write-Host "  Site: '$SiteName' (ID $siteId)"
Write-Host '  This requires port 80 to be reachable from the internet for the HTTP-01 challenge.'

$wacsArgs = @(
    '--source', 'manual',
    '--host', $Domain,
    '--validation', 'selfhosting',
    '--store', 'certificatestore',
    '--installation', 'iis',
    '--installationsiteid', $siteId,
    '--emailaddress', $ContactEmail,
    '--accepttos'
)

& $wacsExe @wacsArgs
if ($LASTEXITCODE -ne 0) {
    throw "win-acme exited with code $LASTEXITCODE.  Check output above for details."
}
Write-Host "  Certificate issued and HTTPS binding created on port 443."
Write-Host "  A Windows Scheduled Task has been registered for automatic renewal."

# ---------------------------------------------------------------------------
# 5. Configure HTTP -> HTTPS redirect via IIS URL Rewrite
# ---------------------------------------------------------------------------
Write-Step "Configuring HTTP to HTTPS redirect for site '$SiteName'..."

$webConfigPath = Join-Path $sitePhysPath 'web.config'
$ruleName      = 'HTTP to HTTPS'

# Load or create web.config
if (Test-Path $webConfigPath) {
    [xml]$webConfig = Get-Content $webConfigPath -Raw
} else {
    [xml]$webConfig = '<?xml version="1.0" encoding="UTF-8"?><configuration></configuration>'
}

# Ensure /configuration/system.webServer node exists
$sws = $webConfig.SelectSingleNode('/configuration/system.webServer')
if (-not $sws) {
    $sws = $webConfig.CreateElement('system.webServer')
    $webConfig.configuration.AppendChild($sws) | Out-Null
}

# Ensure /configuration/system.webServer/rewrite node exists
$rewrite = $sws.SelectSingleNode('rewrite')
if (-not $rewrite) {
    $rewrite = $webConfig.CreateElement('rewrite')
    $sws.AppendChild($rewrite) | Out-Null
}

# Ensure /configuration/system.webServer/rewrite/rules node exists
$rules = $rewrite.SelectSingleNode('rules')
if (-not $rules) {
    $rules = $webConfig.CreateElement('rules')
    $rewrite.AppendChild($rules) | Out-Null
}

# Check whether the rule already exists
$existingRule = $rules.SelectSingleNode("rule[@name='$ruleName']")
if ($existingRule) {
    Write-Host "  Redirect rule '$ruleName' already present in web.config - skipped."
} else {
    # Build the rule element
    $rule = $webConfig.CreateElement('rule')
    $rule.SetAttribute('name', $ruleName)
    $rule.SetAttribute('enabled', 'true')
    $rule.SetAttribute('stopProcessing', 'true')

    $match = $webConfig.CreateElement('match')
    $match.SetAttribute('url', '(.*)')
    $rule.AppendChild($match) | Out-Null

    $conditions = $webConfig.CreateElement('conditions')
    $conditions.SetAttribute('logicalGrouping', 'MatchAll')
    $conditions.SetAttribute('trackAllCaptures', 'false')
    $cond = $webConfig.CreateElement('add')
    $cond.SetAttribute('input', '{HTTPS}')
    $cond.SetAttribute('pattern', 'off')
    $cond.SetAttribute('ignoreCase', 'true')
    $conditions.AppendChild($cond) | Out-Null
    $rule.AppendChild($conditions) | Out-Null

    $action = $webConfig.CreateElement('action')
    $action.SetAttribute('type', 'Redirect')
    $action.SetAttribute('url', 'https://{HTTP_HOST}/{R:1}')
    $action.SetAttribute('redirectType', 'Permanent')
    $rule.AppendChild($action) | Out-Null

    $rules.AppendChild($rule) | Out-Null

    $webConfig.Save($webConfigPath)
    Write-Host "  Redirect rule '$ruleName' added to: $webConfigPath"
    Write-Host '  All HTTP requests will now receive a 301 Permanent redirect to HTTPS.'
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '---------------------------------------------------------------' -ForegroundColor Green
Write-Host ' SSL setup complete.' -ForegroundColor Green
Write-Host '---------------------------------------------------------------' -ForegroundColor Green
Write-Host "  HTTPS URL : https://$Domain/"
Write-Host "  Certificate issued by Let's Encrypt; auto-renews via win-acme scheduled task."
Write-Host ''
Write-Host '  Port 80 status: OPEN (required for ACME HTTP-01 renewal challenges).'
Write-Host '  To close port 80 after issuance, update the NSG rule ''AllowHTTP'' to'
Write-Host '  Deny and reconfigure win-acme to use TLS-ALPN-01 validation.'
Write-Host '---------------------------------------------------------------' -ForegroundColor Green
