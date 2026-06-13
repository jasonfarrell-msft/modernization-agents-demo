// Reference Bicep: User-Assigned Managed Identity, role assignments, and attachment to a Container App.
// Adapt the compute resource (App Service, Function, AKS, VM) to your scenario.

targetScope = 'resourceGroup'

@description('Base name for resources.')
param baseName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Existing Key Vault resource ID this workload should read from.')
param keyVaultId string

@description('Existing Storage Account resource ID this workload should access.')
param storageAccountId string

@description('Container Apps environment ID.')
param containerAppsEnvironmentId string

@description('Container image (e.g., myacr.azurecr.io/catalog-api:1.0.0).')
param containerImage string

// --- 1. User-Assigned Managed Identity ---------------------------------------
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${baseName}'
  location: location
}

// --- 2. RBAC role assignments (least privilege) ------------------------------
// Built-in role IDs: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles

var roleIds = {
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  storageBlobDataReader: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: last(split(keyVaultId, '/'))
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: last(split(storageAccountId, '/'))
}

resource kvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, uami.id, roleIds.keyVaultSecretsUser)
  scope: keyVault
  properties: {
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.keyVaultSecretsUser)
  }
}

resource storageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, uami.id, roleIds.storageBlobDataReader)
  scope: storageAccount
  properties: {
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.storageBlobDataReader)
  }
}

// --- 3. Container App with the UAMI attached ---------------------------------
resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${baseName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: baseName
          image: containerImage
          env: [
            // DefaultAzureCredential reads this to pick the right UAMI.
            { name: 'AZURE_CLIENT_ID', value: uami.properties.clientId }
            { name: 'Azure__KeyVaultUri', value: 'https://${keyVault.name}.vault.azure.net/' }
            { name: 'Azure__Storage__BlobUri', value: storageAccount.properties.primaryEndpoints.blob }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

output uamiClientId string = uami.properties.clientId
output uamiPrincipalId string = uami.properties.principalId
output containerAppFqdn string = app.properties.configuration.ingress.fqdn
