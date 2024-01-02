#consider replacing this with AzAPI call. Current resource seems to have a polling bug.

#deploy additional clusters
resource "azapi_resource" "clusters" {
  for_each = var.clusters

  type      = "Microsoft.AVS/privateClouds/clusters@2022-05-01"
  name      = each.key
  parent_id = azapi_resource.this_private_cloud.id

  body = jsonencode({
    sku = {
      name = each.value.sku_name
    }
    properties = {
      clusterSize = each.value.cluster_node_count
    }

  })

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}

/*
resource "azurerm_vmware_cluster" "example" {
  for_each = var.clusters
  
  name               = each.key
  vmware_cloud_id    = azapi_resource.this_private_cloud.id
  cluster_node_count = each.value.cluster_node_count
  sku_name           = each.value.sku_name
}
*/
