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

function Wait-AppPoolState {
    param([string]$Name, [string]$Desired, [int]$TimeoutSeconds = 30)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $state = (Get-WebAppPoolState -Name $Name).Value
        if ($state -eq $Desired) { return $true }
        Start-Sleep -Milliseconds 750
    }
    return ((Get-WebAppPoolState -Name $Name).Value -eq $Desired)
}

function Set-AppPoolState {
    # Resilient start/stop: WAS can briefly reject control messages (0x80070425)
    # while the pool is mid-transition. Retry until the desired state is reached.
    param([string]$Name, [ValidateSet('Start','Stop')] [string]$Action)
    $desired = if ($Action -eq 'Start') { 'Started' } else { 'Stopped' }
    for ($attempt = 1; $attempt -le 8; $attempt++) {
        $state = (Get-WebAppPoolState -Name $Name).Value
        if ($state -eq $desired) { return }
        try {
            if ($Action -eq 'Start') { Start-WebAppPool -Name $Name } else { Stop-WebAppPool -Name $Name }
        }
        catch {
            # Transitional WAS error; wait and retry.
        }
        if (Wait-AppPoolState -Name $Name -Desired $desired -TimeoutSeconds 15) { return }
        Start-Sleep -Seconds 2
    }
    throw "App pool '$Name' did not reach state '$desired'."
}

try {
    Set-AppPoolState -Name $AppPoolName -Action 'Stop'

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
    Set-AppPoolState -Name $AppPoolName -Action 'Start'
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
