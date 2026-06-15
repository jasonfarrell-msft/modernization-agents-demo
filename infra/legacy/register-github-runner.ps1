#Requires -RunAsAdministrator
param(
    [string]$RunnerUrl = $env:GITHUB_RUNNER_URL,
    [string]$RegistrationToken = $env:GITHUB_RUNNER_REGISTRATION_TOKEN,
    [string]$RunnerName = $env:COMPUTERNAME,
    [string]$Labels = 'self-hosted,Windows,X64,iis-deploy',
    [string]$RunnerRoot = 'C:\actions-runner',
    [string]$RunnerVersion = '2.325.0'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RunnerUrl)) {
    throw 'Runner URL is required. Provide -RunnerUrl or set GITHUB_RUNNER_URL.'
}
if ([string]::IsNullOrWhiteSpace($RegistrationToken)) {
    throw 'Runner registration token is required. Provide -RegistrationToken or set GITHUB_RUNNER_REGISTRATION_TOKEN.'
}

$existingService = Get-Service | Where-Object { $_.Name -like 'actions.runner.*' } | Select-Object -First 1
if ($existingService) {
    Write-Host "GitHub runner service '$($existingService.Name)' already exists."
    if ($existingService.Status -ne 'Running') {
        Start-Service -Name $existingService.Name
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $RunnerRoot | Out-Null
$runnerZip = Join-Path $RunnerRoot ("actions-runner-win-x64-$RunnerVersion.zip")
$configCmd = Join-Path $RunnerRoot 'config.cmd'

if (-not (Test-Path $configCmd)) {
    $downloadUrl = "https://github.com/actions/runner/releases/download/v$RunnerVersion/actions-runner-win-x64-$RunnerVersion.zip"
    Write-Host 'Downloading GitHub Actions runner...'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $runnerZip

    Write-Host 'Extracting runner package...'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($runnerZip, $RunnerRoot, $true)
}

$arguments = @(
    '--unattended',
    '--url', $RunnerUrl,
    '--token', $RegistrationToken,
    '--name', $RunnerName,
    '--labels', $Labels,
    '--runasservice',
    '--work', '_work',
    '--replace'
)

Write-Host 'Configuring runner as a Windows service...'
$process = Start-Process -FilePath $configCmd -ArgumentList $arguments -WorkingDirectory $RunnerRoot -NoNewWindow -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Runner configuration failed with exit code $($process.ExitCode)."
}

$service = Get-Service | Where-Object { $_.Name -like 'actions.runner.*' } | Select-Object -First 1
if (-not $service) {
    throw 'Runner service was not found after configuration.'
}
if ($service.Status -ne 'Running') {
    Start-Service -Name $service.Name
}

Write-Host "Runner service '$($service.Name)' is installed and running."
