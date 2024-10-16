#Create the dhcp configuration
resource "azapi_resource" "dhcp" {
  for_each = var.dhcp_configuration

  type = "Microsoft.AVS/privateClouds/workloadNetworks/dhcpConfigurations@2023-09-01"
  body = jsondecode(upper(each.value.dhcp_type) == "RELAY" ? jsonencode(
    {
      properties = {
        displayName     = each.value.display_name
        dhcpType        = upper(each.value.dhcp_type)
        serverAddresses = each.value.relay_server_addresses
      }
    }) : jsonencode(
    {
      properties = {
        displayName   = each.value.display_name
        dhcpType      = upper(each.value.dhcp_type)
        leaseTime     = each.value.server_lease_time
        serverAddress = each.value.server_address
      }
    }
  ))
  name      = each.key
  parent_id = "${azapi_resource.this_private_cloud.id}/workloadNetworks/default"

  timeouts {
    create = "4h"
    delete = "4h"
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
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
    azapi_resource.dns_forwarder_zones
  ]
}
