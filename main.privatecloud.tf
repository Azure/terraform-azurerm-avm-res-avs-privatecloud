#defaulting to azAPI for private cloud provisioning due to issues with feature lag on AzureRM for AVS
#and need to avoid breaking changes

#pre-creating the body as a local to allow for handling issues with the API not accepting null values.
locals {
  base_body = {
    sku = {
      name = lower(var.sku_name)
    }
  }

  base_properties = {
    managementCluster = {
      clusterSize = var.management_cluster_size
    }
    
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

  #merge the extended network Blocks value into the properties if it exists
  properties_map_json = (length(var.extended_network_blocks) == 0) ? jsonencode(local.base_properties) : jsonencode(merge(local.base_properties, { extendedNetworkBlocks = var.extended_network_blocks }))
  full_body = jsonencode(merge(local.base_body, { properties = jsondecode(local.properties_map_json) } )) #merge the properties map into the body map
}

#build a base private cloud resource then modify it as needed.
resource "azapi_resource" "this_private_cloud" {
  type = "Microsoft.AVS/privateClouds@2023-03-01" 
  body = local.full_body
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
