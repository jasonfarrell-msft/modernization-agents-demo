#Requires -RunAsAdministrator
param(
    [string]$SqlInstanceName = 'SQLEXPRESS',
    [string]$SqlSaPassword = $env:SQL_SA_PASSWORD,
    [string]$OgeAppPassword = $env:OGE_APP_PASSWORD,
    [string]$SqlSetupBootstrapUrl = 'https://go.microsoft.com/fwlink/?linkid=866658',
    [string]$RunnerUrl = $(if ($env:GITHUB_RUNNER_URL) { $env:GITHUB_RUNNER_URL } else { 'https://github.com/jasonfarrell-msft/modernization-agents-demo' }),
    [string]$RunnerRegistrationToken = $env:GITHUB_RUNNER_REGISTRATION_TOKEN,
    [string]$RunnerName = $env:COMPUTERNAME,
    [string]$RunnerLabels = 'self-hosted,Windows,X64,iis-deploy',
    [string]$ContactEmail = $env:LETSENCRYPT_CONTACT_EMAIL,
    [switch]$SkipRunnerRegistration,
    [switch]$SkipSsl
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SqlSaPassword)) {
    throw 'SQL SA password is required. Provide -SqlSaPassword or set SQL_SA_PASSWORD.'
}
if ([string]::IsNullOrWhiteSpace($OgeAppPassword)) {
    throw 'OGE app SQL password is required. Provide -OgeAppPassword or set OGE_APP_PASSWORD.'
}
if ((-not $SkipRunnerRegistration) -and [string]::IsNullOrWhiteSpace($RunnerRegistrationToken)) {
    throw 'Runner registration token is required unless -SkipRunnerRegistration is used.'
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host 'Step 1/5: Install SQL Server Express'
& "$scriptRoot\install-sql-express.ps1" -InstanceName $SqlInstanceName -SaPassword $SqlSaPassword -SqlSetupBootstrapUrl $SqlSetupBootstrapUrl

Write-Host 'Step 2/5: Provision OgeFieldOps database'
& "$scriptRoot\provision-legacy-db.ps1" -SqlServerInstance "localhost\$SqlInstanceName" -SaPassword $SqlSaPassword -OgeAppPassword $OgeAppPassword

Write-Host 'Step 3/5: Install IIS + ASP.NET features'
& "$scriptRoot\install-iis.ps1"

if (-not $SkipRunnerRegistration) {
    Write-Host 'Step 4/5: Register self-hosted GitHub Actions runner'
    & "$scriptRoot\register-github-runner.ps1" -RunnerUrl $RunnerUrl -RegistrationToken $RunnerRegistrationToken -RunnerName $RunnerName -Labels $RunnerLabels
}
else {
    Write-Host 'Step 4/5: Skipped runner registration'
}

if ((-not $SkipSsl) -and (-not [string]::IsNullOrWhiteSpace($ContactEmail))) {
    Write-Host 'Step 5/5: Configure HTTPS certificate and redirect'
    & "$scriptRoot\install-ssl.ps1" -ContactEmail $ContactEmail
}
else {
    Write-Host 'Step 5/5: Skipped SSL setup (set ContactEmail to enable)'
}

Write-Host 'Legacy VM setup complete.'
