// infra/bicep/app.bicep
param location string = resourceGroup().location
param environmentName string
param containerAppName string
param containerImage string
param keyVaultName string
param userAssignedIdentityId string
param vnetSubnetId string

// 1. The Container Apps Environment (The Landing Zone)
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  properties: {
    vnetConfiguration: {
      internal: false // UPDATED: Allows Public Ingress while remaining attached to the VNet
      infrastructureSubnetId: vnetSubnetId
    }
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
  }
}

// 2. The Spring PetClinic Application
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true // External to the ACA Environment, but still internal to the VNet
        targetPort: 8080
      }
      secrets: [
        {
          name: 'mysql-user'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/db-user'
          identity: userAssignedIdentityId
        }
        {
          name: 'mysql-password'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/db-password'
          identity: userAssignedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'petclinic'
          image: containerImage
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'mysql'
            }
            {
              name: 'MYSQL_URL'
              // Target Flexible Server via Private DNS integration
              value: 'jdbc:mysql://tgt-petclinic-mysql.database.azure.com:3306/petclinic?useSSL=true&requireSSL=true'
            }
            {
              name: 'MYSQL_USER'
              secretRef: 'mysql-user'
            }
            {
              name: 'MYSQL_PASS'
              secretRef: 'mysql-password'
            }
            {
              name: 'EXTERNAL_API_URL'
              value: 'https://production-egress-api.internal'
            }
          ]
          resources: {
            cpu: json('1.0')
            memory: '2.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
}