locals {
  netapp_attachments = flatten([for ds_key, datastore in var.netapp_files_datastores : [
    for cluster_name in datastore.cluster_names : {
      attachment_name           = "${ds_key}-${cluster_name}"
      netapp_volume_resource_id = datastore.netapp_volume_resource_id
      cluster_name              = cluster_name
    }
  ]])
}

resource "azurerm_vmware_netapp_volume_attachment" "attach_datastores" {
  for_each = { for datastore in local.netapp_attachments : datastore.attachment_name => datastore }

  name              = each.value.attachment_name
  netapp_volume_id  = each.value.netapp_volume_resource_id
  vmware_cluster_id = "${azapi_resource.this_private_cloud.id}/clusters/${each.value.cluster_name}"

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
    azapi_resource.dhcp,
    azapi_resource.segments,
    #azapi_resource.current_status_identity_sources,
    azapi_resource.remove_existing_identity_source,
    azapi_resource.configure_identity_sources
  ]
}
