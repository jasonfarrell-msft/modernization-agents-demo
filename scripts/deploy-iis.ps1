param(
    [Parameter(Mandatory = $true)]
    [string]$PublishPath,

    [Parameter(Mandatory = $true)]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true)]
    [string]$SitePath,

    [int]$BindingPort = 80
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $PublishPath)) {
    throw "Publish path '$PublishPath' does not exist."
}

Import-Module WebAdministration

$module = Get-WebGlobalModule -Name AspNetCoreModuleV2 -ErrorAction SilentlyContinue
if (-not $module) {
    throw 'ASP.NET Core Hosting Bundle is not installed on this IIS server. Install it before deploying the app.'
}

if (-not (Test-Path $SitePath)) {
    New-Item -ItemType Directory -Path $SitePath -Force | Out-Null
}

$appPoolPath = "IIS:\AppPools\$AppPoolName"
if (-not (Test-Path $appPoolPath)) {
    New-WebAppPool -Name $AppPoolName | Out-Null
}
Set-ItemProperty $appPoolPath -Name managedRuntimeVersion -Value ''

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

    $robocopyArgs = @(
        $PublishPath,
        $SitePath,
        '/MIR',
        '/XD',
        'uploads',
        '/XF',
        'legacy-upload-demo.db',
        'legacy-upload-demo.db-shm',
        'legacy-upload-demo.db-wal',
        'appsettings.Production.json',
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

$uploadsDir = Join-Path $SitePath 'uploads'
New-Item -ItemType Directory -Path $uploadsDir -Force | Out-Null

$appPoolIdentity = "IIS AppPool\$AppPoolName"
$acl = Get-Acl $SitePath
$writeRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $appPoolIdentity, 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
$acl.AddAccessRule($writeRule)
Set-Acl -Path $SitePath -AclObject $acl

Write-Host "Deployed '$SiteName' to '$SitePath'."
exit 0
