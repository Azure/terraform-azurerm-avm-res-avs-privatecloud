locals {
  netapp_attachments = flatten([ for ds_key, datastore in var.netapp_files_datastores : [
    for cluster_name in datastore.cluster_names : {
      attachment_name = "${ds_key}-${cluster_name}"
      netapp_volume_resource_id = datastore.netapp_volume_resource_id
      cluster_name = cluster_name
    }
  ]])
}

resource "azurerm_vmware_netapp_volume_attachment" "attach_datastores" {
  for_each = { for datastore in local.netapp_attachments : datastore.attachment_name => datastore } 
  
  name              = each.value.attachment_name
  netapp_volume_id  = each.value.netapp_volume_resource_id
  vmware_cluster_id = "${azapi_resource.this_private_cloud.id}/clusters/${each.value.cluster_name}"
}
