// Snippet for NSG Egress Rules
resource appSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-aca-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-MySQL-Egress'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          // In production, this targets the specific Flexible Server Subnet/IP
          destinationAddressPrefix: 'VirtualNetwork' 
        }
      }
      {
        name: 'Allow-AppInsights-Telemetry'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureMonitor' // Service Tag
        }
      }
      {
        name: 'Deny-All-Outbound'
        properties: {
          priority: 4096
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }