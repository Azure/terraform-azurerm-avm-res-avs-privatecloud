#defaulting to azAPI for private cloud provisioning due to issues with feature lag on AzureRM for AVS
#and need to avoid breaking changes

#pre-creating the body as a local to allow for handling issues with the API not accepting null values.
locals {
  availability_map = merge(local.primary_zone_map, local.secondary_zone_map, local.base_properties_availability) #build the availability map
  base_body = {
    sku = {
      name = lower(var.sku_name)
    }
  }
  base_properties = {
    managementCluster = {
      clusterSize = var.management_cluster_size
    }

    networkBlock    = var.avs_network_cidr
    nsxtPassword    = local.nsxt_password
    vcenterPassword = local.vcenter_password
    internet        = var.internet_enabled ? "Enabled" : "Disabled"
  }
  base_properties_availability = {
    strategy = var.enable_stretch_cluster ? "DualZone" : "SingleZone"
  }
  full_body        = merge(local.base_body, { properties = local.properties_map }) #merge the properties map into the body map
  primary_zone_map = jsondecode(var.primary_zone != null ? jsonencode({ zone = var.primary_zone }) : jsonencode({}))
  properties_map   = merge(local.base_properties, { availability = local.availability_map }, local.properties_map_enb) #build the properties map
  #merge the extended network Blocks value into the properties if it exists
  properties_map_enb = jsondecode((length(var.extended_network_blocks) == 0) ? jsonencode({}) : jsonencode({ extendedNetworkBlocks = var.extended_network_blocks }))
  secondary_zone_map = jsondecode(var.secondary_zone != null ? jsonencode({ secondaryZone = var.secondary_zone }) : jsonencode({}))
}

#build a base private cloud resource then modify it as needed.
resource "azapi_resource" "this_private_cloud" {
  type                   = "Microsoft.AVS/privateClouds@2023-03-01"
  body                   = local.full_body
  location               = var.location
  name                   = var.name
  parent_id              = var.resource_group_resource_id
  response_export_values = ["*"]
  tags                   = var.tags

  #TODO: Test to see if a lifecycle block is needed when the NSXT or VCenter passwords change
  timeouts {
    create = "15h"
    delete = "4h"
  }
}
