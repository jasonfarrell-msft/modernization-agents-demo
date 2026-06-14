using './main.bicep'

param adminUsername = 'azureadmin'
param adminPassword = readEnvironmentVariable('VM_ADMIN_PASSWORD')
param vmName = 'vm-legacy-swc'
param vmSize = 'Standard_B2s'
param publicIpSku = 'Standard'
param customScriptUri = ''
