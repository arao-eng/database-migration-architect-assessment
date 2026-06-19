@description('The location for all resources.')
param location string = resourceGroup().location

@description('The administrator username for the SQL Managed Instance.')
param sqlAdminLogin string = 'sqladmin'

@description('The administrator password for the SQL Managed Instance.')
@secure()
param sqlAdminPassword string

@description('A unique suffix for globally unique resource names.')
param uniqueSuffix string = uniqueString(resourceGroup().id)

// ==========================================
// 1. Networking (VNet, NSG, Route Table)
// ==========================================

resource sqlMiNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-sqlmi-${uniqueSuffix}'
  location: location
  properties: {} // Azure injects mandatory rules upon delegation
}

resource sqlMiRouteTable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'rt-sqlmi-${uniqueSuffix}'
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-eshop-migration'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'snet-sqlmi'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: sqlMiNsg.id }
          routeTable: { id: sqlMiRouteTable.id }
          delegations: [
            {
              name: 'managedInstanceDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
      {
        name: 'snet-webapp'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'webAppDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

// ==========================================
// 2. Azure SQL Managed Instance
// ==========================================

resource sqlManagedInstance 'Microsoft.Sql/managedInstances@2022-08-01-preview' = {
  name: 'sqlmi-eshop-${uniqueSuffix}'
  location: location
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 4 // Minimum vCores
  }
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    subnetId: vnet.properties.subnets[0].id
    publicDataEndpointEnabled: true // Allows local sqlpackage / SSMS imports via port 3342
    proxyOverride: 'Proxy'
    timezoneId: 'UTC'
  }
}

// ==========================================
// 3. Azure Container Registry (ACR)
// ==========================================

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acreshop${uniqueSuffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// ==========================================
// 4. App Service (Linux) with VNet Integration
// ==========================================

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-eshop-${uniqueSuffix}'
  location: location
  kind: 'linux'
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
  }
  properties: {
    reserved: true // Required for Linux
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-eshop-${uniqueSuffix}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: vnet.properties.subnets[1].id // VNet Integration
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acr.name}.azurecr.io/eshopweb:latest'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        // The internal connection string using the private FQDN
        {
          name: 'ConnectionStrings__CatalogConnection'
          value: 'Server=${sqlManagedInstance.properties.fullyQualifiedDomainName};Database=eShopOnWebDb;User Id=${sqlAdminLogin};Password=${sqlAdminPassword};TrustServerCertificate=True;'
        }
        {
          name: 'ConnectionStrings__IdentityConnection'
          value: 'Server=${sqlManagedInstance.properties.fullyQualifiedDomainName};Database=eShopOnWebDb;User Id=${sqlAdminLogin};Password=${sqlAdminPassword};TrustServerCertificate=True;'
        }
      ]
    }
  }
}

// ==========================================
// Outputs
// ==========================================

output acrName string = acr.name
output webAppName string = webApp.name
output sqlMiPrivateEndpoint string = sqlManagedInstance.properties.fullyQualifiedDomainName
output sqlMiPublicEndpoint string = replace(sqlManagedInstance.properties.fullyQualifiedDomainName, '.database.windows.net', '.public.database.windows.net')