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

  #adding lifecycle block to handle deployment issue with parent_id 
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

  depends_on = [azapi_resource.this_private_cloud] #setting explicit dependencies to force deployment order
}

