targetScope = 'resourceGroup'

@description('Azure region for the deployment. Default is Sweden Central for the requested demo resource group.')
param location string = 'swedencentral'

@description('Name of the VM to create for the legacy demo hosting.')
param vmName string = 'vm-legacy-swc'

@description('Admin username for the Windows VM.')
param adminUsername string = 'azureadmin'

@description('Admin password for the Windows VM.')
@secure()
param adminPassword string

@description('Virtual machine size for the legacy demo environment.')
param vmSize string = 'Standard_B2s'

@description('Optional public URL to a PowerShell custom script for IIS/legacy demo setup on the VM. Leave empty to skip post-deploy setup.')
param customScriptUri string = ''

@description('SKU for the public IP address.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Standard'

@description('Tags applied to the legacy VM hosting resources.')
param resourceTags object = {
  SecurityControl: 'Ignore'
}

var vnetName = 'vnet-legacy-demo-swc'
var subnetName = 'subnet-legacy-demo-swc'
var nicName = '${vmName}-nic'
var publicIpName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'
var vmImagePublisher = 'MicrosoftWindowsServer'
var vmImageOffer = 'WindowsServer'
var vmImageSku = '2022-datacenter-g2'
var vmImageVersion = 'latest'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  tags: resourceTags
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: toLower(vmName)
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: resourceTags
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 1020
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: resourceTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/24'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.10.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  tags: resourceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetName)
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: resourceTags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: vmImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource vmIisSetup 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (!empty(customScriptUri)) {
  parent: vm
  name: 'InstallIISAndLegacyDemo'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Bypass -File install-iis.ps1'
    }
  }
}

output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output fqdn string = publicIp.properties.dnsSettings.fqdn
output sshRdpEndpoint string = 'RDP: ${publicIp.properties.ipAddress}:3389; HTTP: http://${publicIp.properties.dnsSettings.fqdn}/; HTTPS: https://${publicIp.properties.dnsSettings.fqdn}/'
