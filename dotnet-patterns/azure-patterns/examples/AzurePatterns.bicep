// Example: Azure Bicep template demonstrating azure-patterns
// Patterns:
// - Blob Storage with Standard_LRS (Pattern 1)
// - Azure SQL with Serverless compute (Pattern 2)
// - Development-tier SKUs (Pattern 3)

param environment string = 'dev'  // 'dev' or 'prod'
param location string = resourceGroup().location
param appName string = 'legacy-upload-demo'
param sqlAdminLogin string = 'sqladmin'

// Pattern 3: Development-tier SKU selection
var appServiceSku = environment == 'dev' ? 'B1' : 'S1'
var appServiceCapacity = environment == 'dev' ? 1 : 2
var sqlMinCapacity = environment == 'dev' ? 0.5 : 1.0
var sqlMaxCapacity = environment == 'dev' ? 2 : 4
var containerAppCpu = environment == 'dev' ? '0.25' : '0.5'
var containerAppMemory = environment == 'dev' ? '0.5Gi' : '1Gi'

// Pattern 1: Blob Storage with LRS
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${replace(appName, '-', '')}${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'BlobStorage'
  sku: {
    name: 'Standard_LRS'  // Always LRS for dev
  }
  properties: {
    accessTier: 'Hot'  // Hot for frequently accessed data
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'  // Secure by default
      bypass: 'AzureServices'
    }
  }
}

// Create blob container
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/uploads'
  properties: {
    publicAccess: 'None'  // Private container
  }
}

// Pattern 2: Azure SQL Database with Serverless compute
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-${appName}-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: environment() == 'prod' ? generatePassword() : 'TempPassword123!'  // Use Key Vault in prod
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: '${sqlServer.name}/${appName}-db'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'GeneralPurpose'
    computeModel: 'Serverless'  // Always Serverless for dev
    autoPauseDelayInMinutes: 60  // Auto-pause after 60 minutes of inactivity
    minCapacity: sqlMinCapacity   // 0.5 vCore for dev
    maxCapacity: sqlMaxCapacity   // 2 vCore max for dev
  }
}

// Allow Azure services to access SQL
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  name: '${sqlServer.name}/AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Pattern 3: App Service with development SKU
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'plan-${appName}'
  location: location
  sku: {
    name: appServiceSku  // B1 for dev, S1 for prod
    capacity: appServiceCapacity
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-${appName}-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'  // Managed Identity for auth
  }
  properties: {
    serverFarmId: appServicePlan.id
    alwaysOn: environment == 'dev' ? false : true  // Disable always-on for dev (cost savings)
    http20Enabled: true
    minTlsVersion: '1.2'
    siteConfig: {
      appSettings: [
        {
          name: 'Azure:Storage:AccountName'
          value: storageAccount.name
        }
        {
          name: 'Azure:Storage:ContainerName'
          value: 'uploads'
        }
        {
          name: 'Azure:Sql:ServerName'
          value: sqlServer.properties.fullyQualifiedDomainName
        }
        {
          name: 'Azure:Sql:DatabaseName'
          value: appName
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${appName}-db;Encrypt=true;TrustServerCertificate=false;Authentication=Active Directory Managed Identity;'
          type: 'SQLAzure'
        }
      ]
    }
  }
}

// Assign Managed Identity permissions to Blob Storage
resource blobStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2023-04-01-preview' = {
  name: guid(storageAccount.id, appService.identity.principalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')  // Storage Blob Data Contributor
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign Managed Identity permissions to SQL Server
resource sqlServerRoleAssignment 'Microsoft.Authorization/roleAssignments@2023-04-01-preview' = {
  name: guid(sqlServer.id, appService.identity.principalId, '6d8ee4ec-f05a-4a71-8b95-504218e5f330')  // SQL Server Contributor
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '6d8ee4ec-f05a-4a71-8b95-504218e5f330')
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output sqlServerName string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = appName
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output computeTierInfo string = environment == 'dev' 
  ? 'Serverless (0.5-2 vCore, auto-pause after 60 min)'
  : 'Serverless (1-4 vCore)'
