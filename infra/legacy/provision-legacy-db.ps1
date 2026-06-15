#Requires -RunAsAdministrator
param(
    [string]$SqlServerInstance = 'localhost\\SQLEXPRESS',
    [string]$DatabaseName = 'OgeFieldOps',
    [string]$SaPassword = $env:SQL_SA_PASSWORD,
    [string]$AppLogin = 'oge_app',
    [string]$OgeAppPassword = $env:OGE_APP_PASSWORD,
    [string]$SchemaScriptPath = '',
    [string]$SeedScriptPath = '',
    [string]$SchemaScriptUrl = 'https://raw.githubusercontent.com/jasonfarrell-msft/modernization-agents-demo/main/legacy-upload-demo/OgeFieldOps.Web/Database/Schema.sql',
    [string]$SeedScriptUrl = 'https://raw.githubusercontent.com/jasonfarrell-msft/modernization-agents-demo/main/legacy-upload-demo/OgeFieldOps.Web/Database/Seed.sql'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SaPassword)) {
    throw 'SA password is required. Provide -SaPassword or set SQL_SA_PASSWORD.'
}
if ([string]::IsNullOrWhiteSpace($OgeAppPassword)) {
    throw 'App password is required. Provide -OgeAppPassword or set OGE_APP_PASSWORD.'
}

function Get-SqlScriptContent {
    param(
        [string]$Path,
        [string]$Url,
        [string]$Name
    )

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        if (-not (Test-Path $Path)) {
            throw "$Name script file was not found at '$Path'."
        }
        return Get-Content -Path $Path -Raw
    }

    Write-Host "Downloading $Name script..."
    return (Invoke-WebRequest -Uri $Url).Content
}

function Split-SqlBatches {
    param([string]$ScriptText)

    $splitPattern = '(?im)^\s*GO\s*$(?:\r?\n)?'
    $rawBatches = [regex]::Split($ScriptText, $splitPattern)
    return $rawBatches | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Invoke-SqlBatch {
    param(
        [string]$ConnectionString,
        [string]$CommandText
    )

    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $CommandText
        $command.CommandTimeout = 180
        [void]$command.ExecuteNonQuery()
    }
    finally {
        $connection.Dispose()
    }
}

$schemaSql = Get-SqlScriptContent -Path $SchemaScriptPath -Url $SchemaScriptUrl -Name 'schema'
$seedSql = Get-SqlScriptContent -Path $SeedScriptPath -Url $SeedScriptUrl -Name 'seed'

$dbIdentifier = $DatabaseName.Replace(']', ']]')
$loginIdentifier = $AppLogin.Replace(']', ']]')
$loginLiteral = $AppLogin.Replace("'", "''")
$appPasswordLiteral = $OgeAppPassword.Replace("'", "''")

$masterBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$masterBuilder['Data Source'] = $SqlServerInstance
$masterBuilder['Initial Catalog'] = 'master'
$masterBuilder['User ID'] = 'sa'
$masterBuilder['Password'] = $SaPassword
$masterBuilder['Encrypt'] = $false
$masterBuilder['TrustServerCertificate'] = $true
$masterConnectionString = $masterBuilder.ConnectionString

Invoke-SqlBatch -ConnectionString $masterConnectionString -CommandText @"
IF DB_ID(N'$($DatabaseName.Replace("'", "''"))') IS NULL
BEGIN
    CREATE DATABASE [$dbIdentifier];
END
"@

Invoke-SqlBatch -ConnectionString $masterConnectionString -CommandText @"
IF SUSER_ID(N'$loginLiteral') IS NULL
BEGIN
    CREATE LOGIN [$loginIdentifier] WITH PASSWORD = N'$appPasswordLiteral', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;
END
ELSE
BEGIN
    ALTER LOGIN [$loginIdentifier] WITH PASSWORD = N'$appPasswordLiteral';
END
"@

$dbBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$dbBuilder['Data Source'] = $SqlServerInstance
$dbBuilder['Initial Catalog'] = $DatabaseName
$dbBuilder['User ID'] = 'sa'
$dbBuilder['Password'] = $SaPassword
$dbBuilder['Encrypt'] = $false
$dbBuilder['TrustServerCertificate'] = $true
$databaseConnectionString = $dbBuilder.ConnectionString

Invoke-SqlBatch -ConnectionString $databaseConnectionString -CommandText @"
IF USER_ID(N'$loginLiteral') IS NULL
BEGIN
    CREATE USER [$loginIdentifier] FOR LOGIN [$loginIdentifier];
END
IF IS_ROLEMEMBER(N'db_owner', N'$loginLiteral') <> 1
BEGIN
    EXEC sp_addrolemember N'db_owner', N'$loginLiteral';
END
"@

Write-Host 'Applying schema batches...'
$schemaBatches = Split-SqlBatches -ScriptText $schemaSql
foreach ($batch in $schemaBatches) {
    Invoke-SqlBatch -ConnectionString $databaseConnectionString -CommandText $batch
}

Write-Host 'Applying seed batches...'
$seedBatches = Split-SqlBatches -ScriptText $seedSql
foreach ($batch in $seedBatches) {
    Invoke-SqlBatch -ConnectionString $databaseConnectionString -CommandText $batch
}

Write-Host "Database '$DatabaseName' is provisioned and seeded."
