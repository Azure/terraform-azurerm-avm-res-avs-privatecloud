#Create the segments
resource "azapi_resource" "public_ip" {
  for_each = var.internet_inbound_public_ips

  type = "Microsoft.AVS/privateClouds/workloadNetworks/publicIPs@2023-03-01"
  body = {
    properties = {
      displayName       = each.key
      numberOfPublicIPs = each.value.number_of_ip_addresses
    }
  }
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
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_resource.dhcp,
    azapi_resource.segments,
    #azapi_resource.current_status_identity_sources,
    azapi_resource.remove_existing_identity_source,
    azapi_resource.configure_identity_sources,
    azurerm_vmware_netapp_volume_attachment.attach_datastores
  ]
}
