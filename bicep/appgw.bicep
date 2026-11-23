param location string = resourceGroup().location
param vnetName string = 'az104-06-vnet1'

var agwName = 'az104-appgw'
var agwId = resourceId('Microsoft.Network/applicationGateways', agwName)

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
parent: vnet
name: 'subnet-appgw'
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
name: 'az104-gwpip'
location: location
sku: {
name: 'Standard'
tier: 'Regional'
}
properties: {
publicIPAllocationMethod: 'Static'
}
}

resource agw 'Microsoft.Network/applicationGateways@2023-09-01' = {
name: agwName
location: location
properties: {
sku: {
name: 'Standard_v2'
tier: 'Standard_v2'
capacity: 2
}
enableHttp2: false
gatewayIPConfigurations: [
{
name: 'appGatewayIpConfig'
properties: {
subnet: {
id: subnet.id
}
}
}
]
frontendIPConfigurations: [
{
name: 'appGwPublicFrontendIpIPv4'
properties: {
publicIPAddress: {
id: pip.id
}
}
}
]
frontendPorts: [
{
name: 'port_80'
properties: {
port: 80
}
}
]
backendAddressPools: [
{
name: 'az104-appgwbe'
properties: {
backendAddresses: [
{
ipAddress: '10.60.1.4'
}
{
ipAddress: '10.60.2.4'
}
]
}
}
{
name: 'az104-imagebe'
properties: {
backendAddresses: [
{
ipAddress: '10.60.1.4'
}
]
}
}
{
name: 'az104-videobe'
properties: {
backendAddresses: [
{
ipAddress: '10.60.2.4'
}
]
}
}
]
backendHttpSettingsCollection: [
{
name: 'az104-http'
properties: {
port: 80
protocol: 'Http'
cookieBasedAffinity: 'Disabled'
requestTimeout: 20
}
}
]
httpListeners: [
{
name: 'az104-listener'
properties: {
frontendIPConfiguration: {
id: '${agwId}/frontendIPConfigurations/appGwPublicFrontendIpIPv4'
}
frontendPort: {
id: '${agwId}/frontendPorts/port_80'
}
protocol: 'Http'
}
}
]
urlPathMaps: [
{
name: 'az104-gwrule'
properties: {
defaultBackendAddressPool: {
id: '${agwId}/backendAddressPools/az104-appgwbe'
}
defaultBackendHttpSettings: {
id: '${agwId}/backendHttpSettingsCollection/az104-http'
}
pathRules: [
{
name: 'images'
properties: {
paths: [
'/image/*'
]
backendAddressPool: {
id: '${agwId}/backendAddressPools/az104-imagebe'
}
backendHttpSettings: {
id: '${agwId}/backendHttpSettingsCollection/az104-http'
}
}
}
{
name: 'videos'
properties: {
paths: [
'/video/*'
]
backendAddressPool: {
id: '${agwId}/backendAddressPools/az104-videobe'
}
backendHttpSettings: {
id: '${agwId}/backendHttpSettingsCollection/az104-http'
}
}
}
]
}
}
]
requestRoutingRules: [
{
name: 'az104-gwrule'
properties: {
ruleType: 'PathBasedRouting'
priority: 10
httpListener: {
id: '${agwId}/httpListeners/az104-listener'
}
urlPathMap: {
id: '${agwId}/urlPathMaps/az104-gwrule'
}
}
}
]
}
}

output agwIp string = pip.properties.ipAddress
