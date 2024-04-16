#defaulting to azAPI for private cloud provisioning due to issues with feature lag on AzureRM for AVS
#and need to avoid breaking changes

#build a base private cloud resource then modify it as needed.
resource "azapi_resource" "this_private_cloud" {
  type = "Microsoft.AVS/privateClouds@2023-03-01"
  body = jsonencode({
    sku = {
      name = lower(var.sku_name)
    }
    properties = {
      managementCluster = {
        clusterSize = var.management_cluster_size
      }

      extendedNetworkBlocks = var.extended_network_blocks
      networkBlock          = var.avs_network_cidr
      nsxtPassword          = local.nsxt_password
      vcenterPassword       = local.vcenter_password
      internet              = var.internet_enabled ? "Enabled" : "Disabled"


      availability = {
        secondaryZone = var.secondary_zone
        zone          = var.primary_zone
        strategy      = var.enable_stretch_cluster ? "DualZone" : "SingleZone"
      }
    }
  })
  location               = var.location
  name                   = var.name
  parent_id              = var.resource_group_resource_id
  response_export_values = ["*"]
  tags                   = var.tags

  #TODO: Test to see if a lifecycle block is needed when the NSXT or VCenter passwords change
  timeouts {
    create = "15h"
    delete = "4h"
    update = "4h"
  }
}
