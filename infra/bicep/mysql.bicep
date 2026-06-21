@description('The location for the MySQL Flexible Server.')
param location string = resourceGroup().location

@description('Name of the MySQL Flexible Server. Must be unique across Azure.')
param serverName string = 'tgt-petclinic-mysql'

@description('Database administrator login name.')
param administratorLogin string = 'petclinicadmin'

@description('Database administrator password.')
@secure()
param administratorLoginPassword string

@description('The resource ID of the delegated MySQL subnet (output from network.bicep).')
param delegatedSubnetId string

@description('The resource ID of the Private DNS Zone (output from network.bicep).')
param privateDnsZoneId string

@description('Compute tier of the MySQL Flexible Server.')
param skuName string = 'Standard_B1ms' // Burstable tier, cost-effective for testing/migration

@description('MySQL version')
param version string = '8.0.21'

// 1. The MySQL Flexible Server
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: 'Burstable'
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    network: {
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneResourceId: privateDnsZoneId
    }
    storage: {
      storageSizeGB: 20
      iops: 360
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled' // Keep disabled for dev/test to save costs
    }
  }
}

// 2. The PetClinic Database (Auto-created inside the server)
resource petclinicDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = {
  parent: mysqlServer
  name: 'petclinic'
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_unicode_ci'
  }
}

// Outputs to pass to your Container App deployment
output mysqlServerName string = mysqlServer.name
output mysqlServerFqdn string = mysqlServer.properties.fullyQualifiedDomainName