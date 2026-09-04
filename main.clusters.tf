#consider replacing this with AzAPI call. Current resource seems to have a polling bug.

#deploy additional clusters
resource "azapi_resource" "clusters" {
  for_each = var.clusters

  name      = each.key
  parent_id = azapi_resource.this_private_cloud.id
  type      = "Microsoft.AVS/privateClouds/clusters@2023-09-01"
  body = {
    sku = {
      name = each.value.sku_name
    }
    properties = {
      clusterSize = each.value.cluster_node_count
    }

  }

  timeouts {
    create = "4h"
    delete = "4h"
  }

  #adding lifecycle block to handle deployment issue with parent_id 
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }
  depends_on = [azapi_resource.this_private_cloud] #setting explicit dependencies to force deployment order
}
