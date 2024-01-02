/*
#get the full cluster IDs (need to use AZAPI?)
data "azapi_resource_list" "list_clusters" {
  type                   = "Microsoft.AVS/privateClouds/clusters@2022-05-01"
  parent_id              = azapi_resource.this_private_cloud.id
  response_export_values = ["*"]

  depends_on = [azapi_resource.clusters]
}


resource "azurerm_vmware_netapp_volume_attachment" "test" {
  for_each = var.netapp_files_attachments 

  name              = "example-vmwareattachment"
  netapp_volume_id  = azurerm_netapp_volume.test.id
  vmware_cluster_id = azurerm_vmware_cluster.test.id
}
*/
