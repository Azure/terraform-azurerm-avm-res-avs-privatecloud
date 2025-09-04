#Get the currently configured gateways
data "azapi_resource_action" "avs_gateways" {
  method                 = "GET"
  resource_id            = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default/gateways"
  type                   = "Microsoft.AVS/privateClouds/workloadNetworks/gateways@2024-09-01"
  response_export_values = ["*"]
}

#Create the segments
resource "azapi_resource" "segments" {
  for_each = var.segments

  name      = each.key
  parent_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default"
  type      = "Microsoft.AVS/privateClouds/workloadNetworks/segments@2023-09-01"
  body = {
    properties = {
      connectedGateway = each.value.connected_gateway == null ? [for value in data.azapi_resource_action.avs_gateways.output.value : upper(value.name) if strcontains(value.name, "tnt")][0] : each.value.connected_gateway
      displayName      = each.value.display_name
      subnet = {
        dhcpRanges     = each.value.dhcp_ranges
        gatewayAddress = each.value.gateway_address
      }
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = "4h"
    delete = "4h"
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_resource.dhcp
  ]
}