#Create additional forwarder zones
resource "azapi_resource" "dns_forwarder_zones" {
  for_each = var.dns_forwarder_zones

  type      = "Microsoft.AVS/privateClouds/workloadNetworks/dnsZones@2022-05-01"
  name      = each.key
  parent_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default"
  body = jsonencode({
    properties = {
      displayName  = each.value.display_name
      dnsServerIps = each.value.dns_server_ips
      domain       = each.value.domain_names
      sourceIp     = each.value.source_ip
      #revision     = each.value.revision
    }
  })

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}

#get the default DNS zone details
#read in a private cloud dns services
data "azapi_resource_action" "avs_dns" {
  type                   = "Microsoft.AVS/privateClouds/workloadNetworks/dnsServices@2022-05-01"
  resource_id            = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default/dnsServices"
  response_export_values = ["*"]
  method                 = "GET"

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones
  ]
}

resource "azapi_resource_action" "dns_service" {
  count = (length(keys(var.dns_forwarder_zones))) == 0 ? 0 : 1

  type        = "Microsoft.AVS/privateClouds/workloadNetworks/dnsServices@2022-05-01"
  resource_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default/dnsServices/dns-forwarder"
  #if zone information defined populate the properties
  body = jsonencode({
    properties = {
      defaultDnsZone = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.defaultDnsZone
      displayName    = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.displayName
      dnsServiceIp   = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.dnsServiceIp
      fqdnZones      = try([for key, zone in var.dns_forwarder_zones : key if zone.add_to_default_dns_service], [])
      logLevel       = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.logLevel
    }
  })

  method = "PATCH"
  when   = "apply"


  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}

resource "azapi_resource_action" "dns_service_destroy_non_empty_start" {
  count = length(keys(var.dns_forwarder_zones)) > 0 ? 1 : 0

  type        = "Microsoft.AVS/privateClouds/workloadNetworks/dnsServices@2022-05-01"
  resource_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default/dnsServices/dns-forwarder"
  #if zone information defined populate the properties
  body = jsonencode({
    properties = {
      defaultDnsZone = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.defaultDnsZone
      displayName    = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.displayName
      dnsServiceIp   = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.dnsServiceIp
      fqdnZones      = []
      logLevel       = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.logLevel
      #revision       = 0
    }
  })

  method = "PATCH"
  when   = "destroy"


  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}