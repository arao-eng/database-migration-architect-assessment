@description('Azure region for the network deployment')
param location string = resourceGroup().location

@description('Name of the Virtual Network')
param vnetName string = 'vnet-petclinic-migration'

@description('Name of the subnet for Azure Container Apps')
param containerAppSubnetName string = 'snet-containerapps'

@description('Name of the subnet for Azure Database for MySQL Flexible Server')
param mysqlSubnetName string = 'snet-mysql'

// 1. The Main Virtual Network (The Fortress)
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      // Room A: For the Spring PetClinic Container App
      {
        name: containerAppSubnetName
        properties: {
          addressPrefix: '10.0.0.0/23' // Container Apps require a larger /23 block
          delegations: [
            {
              name: 'aca-delegation'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      // Room B: Exclusively for the Azure MySQL Flexible Server
      {
        name: mysqlSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'mysql-delegation'
              properties: {
                // This tells Azure: "Only MySQL Flexible Servers are allowed in this subnet"
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

// 2. Private DNS Zone (The Internal Phonebook)
// Ensures database traffic never touches the public internet
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.mysql.database.azure.com'
  location: 'global'
}

// 3. Link the DNS Zone to our Virtual Network
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Output the IDs so your App and Database deployments can attach to them later
output vnetId string = vnet.id
output containerAppSubnetId string = vnet.properties.subnets[0].id
output mysqlSubnetId string = vnet.properties.subnets[1].id
output privateDnsZoneId string = privateDnsZone.id