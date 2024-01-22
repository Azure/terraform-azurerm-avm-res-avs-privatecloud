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
      revision     = each.value.revision
      sourceIp     = each.value.source_ip
    }
  })

  #adding lifecycle block to handle replacement issue with parent_id
  #lifecycle {
  #  ignore_changes = [
  ##    parent_id
  #  ]
  #}

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this
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
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.dns_forwarder_zones
  ]
}

#modify the existing DNS Service (only allowing addition of FQDN zones currently)
#resource "azapi_update_resource" "dns_service" {
resource "azapi_resource_action" "dns_service" {
  #check to see if the fqdn_zones match.  If they don't, update the zones. The API doesn't handle this nicely if they match and the update is null

  type        = "Microsoft.AVS/privateClouds/workloadNetworks/dnsServices@2022-05-01"
  resource_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default/dnsServices/dns-forwarder"
  #if zone information is defined populate the properties. Otherwise send an empty body
  body = try(jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.fqdnZones, []) != ([for key, zone in var.dns_forwarder_zones : key if zone.add_to_default_dns_service]) ? jsonencode({
    properties = {
      defaultDnsZone = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.defaultDnsZone
      displayName    = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.displayName
      dnsServiceIp   = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.dnsServiceIp
      fqdnZones      = [for key, zone in var.dns_forwarder_zones : key if zone.add_to_default_dns_service]
      logLevel       = jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.logLevel
      revision       = 0
    }
  }) : "{}"
  #if zone information is defined, use the PATCH method.  Otherwise perform a GET operation to just do a read
  method = try(jsondecode(data.azapi_resource_action.avs_dns.output).value[0].properties.fqdnZones, []) != ([for key, zone in var.dns_forwarder_zones : key if zone.add_to_default_dns_service]) ? "PATCH" : "GET"


  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.dns_forwarder_zones
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}
