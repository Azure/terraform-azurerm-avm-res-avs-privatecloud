#Get the currently configured gateways
data "azapi_resource_action" "avs_gateways" {
  type                   = "Microsoft.AVS/privateClouds/workloadNetworks/gateways@2022-05-01"
  resource_id            = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default/gateways"
  response_export_values = ["*"]
  method                 = "GET"
}

#Create the segments
resource "azapi_resource" "segments" {
  for_each = var.segments

  type      = "Microsoft.AVS/privateClouds/workloadNetworks/segments@2022-05-01"
  name      = each.key
  parent_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default"
  body = jsonencode({
    properties = {
      connectedGateway = each.value.connected_gateway == null ? [for value in jsondecode(data.azapi_resource_action.avs_gateways.output).value : upper(value.name) if strcontains(value.name, "tnt")][0] : each.value.connected_gateway
      displayName      = each.value.display_name
      subnet = {
        dhcpRanges     = each.value.dhcp_ranges
        gatewayAddress = each.value.gateway_address
      }
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
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_resource.dhcp
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}





















output "test" {
  value = [for value in jsondecode(data.azapi_resource_action.avs_dns.output).value : upper(value.name) if strcontains(value.name, "tnt")][0]
}
