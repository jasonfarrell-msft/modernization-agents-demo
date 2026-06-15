#Requires -RunAsAdministrator
param(
    [string]$InstanceName = 'SQLEXPRESS',
    [string]$SaPassword = $env:SQL_SA_PASSWORD,
    [string]$SqlSetupBootstrapUrl = 'https://go.microsoft.com/fwlink/?linkid=866658',
    [string]$WorkingDirectory = 'C:\Temp\SqlExpressSetup'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SaPassword)) {
    throw 'SA password is required. Provide -SaPassword or set SQL_SA_PASSWORD.'
}

$serviceName = "MSSQL`$$InstanceName"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "SQL Server instance '$InstanceName' already exists. Skipping installation."
    if ($service.Status -ne 'Running') {
        Start-Service -Name $serviceName
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $WorkingDirectory | Out-Null
$setupExe = Join-Path $WorkingDirectory 'SQLEXPR_x64_ENU.exe'
$configPath = Join-Path $WorkingDirectory 'ConfigurationFile.ini'

if (-not (Test-Path $setupExe)) {
    Write-Host 'Downloading SQL Server Express installer...'
    Invoke-WebRequest -Uri $SqlSetupBootstrapUrl -OutFile $setupExe
}

@"
[OPTIONS]
ACTION="Install"
FEATURES=SQLENGINE
INSTANCENAME="$InstanceName"
SQLSVCSTARTUPTYPE="Automatic"
SECURITYMODE="SQL"
SAPWD="$SaPassword"
SQLSYSADMINACCOUNTS="BUILTIN\Administrators"
TCPENABLED="1"
NPENABLED="0"
BROWSERSVCSTARTUPTYPE="Automatic"
UpdateEnabled="False"
QUIET="True"
IACCEPTSQLSERVERLICENSETERMS="True"
"@ | Set-Content -Path $configPath -Encoding ASCII

try {
    Write-Host "Installing SQL Server Express instance '$InstanceName'..."
    $process = Start-Process -FilePath $setupExe -ArgumentList "/ConfigurationFile=`"$configPath`" /Q /IACCEPTSQLSERVERLICENSETERMS" -Wait -PassThru
    if (($process.ExitCode -ne 0) -and ($process.ExitCode -ne 3010)) {
        throw "SQL Server Express installation failed with exit code $($process.ExitCode)."
    }
}
finally {
    Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
}

$installedService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $installedService) {
    throw "SQL Server service '$serviceName' was not found after installation."
}

if ($installedService.Status -ne 'Running') {
    Start-Service -Name $serviceName
}

Write-Host "SQL Server Express instance '$InstanceName' is installed and running."
