param(
    [Parameter(Mandatory = $true)]
    [string]$PublishPath,

    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true)]
    [string]$SitePath,

    [int]$BindingPort = 80,

    # Server-local data root that the legacy app writes to (config-defined paths live under here).
    [string]$DataRoot = 'C:\OGE'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $PublishPath)) {
    throw "Publish path '$PublishPath' does not exist."
}

Import-Module WebAdministration

if (-not (Test-Path $SitePath)) {
    New-Item -ItemType Directory -Path $SitePath -Force | Out-Null
}

# --- Classic ASP.NET 4.x application pool (NOT ASP.NET Core) ---
$appPoolPath = "IIS:\AppPools\$AppPoolName"
if (-not (Test-Path $appPoolPath)) {
    New-WebAppPool -Name $AppPoolName | Out-Null
}
Set-ItemProperty $appPoolPath -Name managedRuntimeVersion -Value 'v4.0'
Set-ItemProperty $appPoolPath -Name managedPipelineMode -Value 'Integrated'
Set-ItemProperty $appPoolPath -Name enable32BitAppOnWin64 -Value $false

$sitePathInIis = "IIS:\Sites\$SiteName"
if (-not (Test-Path $sitePathInIis)) {
    New-Website -Name $SiteName -PhysicalPath $SitePath -Port $BindingPort -ApplicationPool $AppPoolName | Out-Null
}
else {
    Set-ItemProperty $sitePathInIis -Name physicalPath -Value $SitePath
    Set-ItemProperty $sitePathInIis -Name applicationPool -Value $AppPoolName
}

$appOffline = Join-Path $SitePath 'app_offline.htm'
Set-Content -Path $appOffline -Value '<html><body>Deployment in progress.</body></html>' -Encoding UTF8

try {
    if ((Get-WebAppPoolState -Name $AppPoolName).Value -eq 'Started') {
        Stop-WebAppPool -Name $AppPoolName
    }

    # Mirror the published site, but never clobber app_offline during the copy.
    $robocopyArgs = @(
        $PublishPath,
        $SitePath,
        '/MIR',
        '/XF',
        'app_offline.htm',
        '/R:2',
        '/W:2',
        '/NFL',
        '/NDL',
        '/NP'
    )

    & robocopy @robocopyArgs
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -gt 7) {
        throw "Robocopy failed with exit code $robocopyExitCode."
    }
}
finally {
    Remove-Item $appOffline -Force -ErrorAction SilentlyContinue
    Start-WebAppPool -Name $AppPoolName
}

# --- Ensure the server-local data directories exist and are writable by the app pool ---
$dataDirs = @(
    (Join-Path $DataRoot 'FieldDocs'),
    (Join-Path $DataRoot 'Logs'),
    (Join-Path $DataRoot 'MailDrop')
)
foreach ($dir in $dataDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$appPoolIdentity = "IIS AppPool\$AppPoolName"
foreach ($target in @($DataRoot, $SitePath)) {
    $acl = Get-Acl $target
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $appPoolIdentity, 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl -Path $target -AclObject $acl
}

Write-Host "Deployed classic ASP.NET MVC5 site '$SiteName' to '$SitePath' (app pool CLR v4.0)."
exit 0
