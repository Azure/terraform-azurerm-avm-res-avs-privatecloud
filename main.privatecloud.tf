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
    vcfLicense      = var.vcf_license
  }
  base_properties_availability = {
    strategy = var.enable_stretch_cluster ? "DualZone" : "SingleZone"
  }
  # Uses the effective gen2 VNet input (new map input first, legacy string fallback).
  base_properties_vnet = local.gen2_effective_virtual_network_id != null ? {
    virtualNetworkId = local.gen2_effective_virtual_network_id
    dnsZoneType      = var.dns_zone_type
  } : {}
  full_body = merge(local.base_body, { properties = merge(local.properties_map, local.base_properties_vnet) }) #merge the properties map into the body map
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  primary_zone_map = jsondecode(var.primary_zone != null ? jsonencode({ zone = var.primary_zone }) : jsonencode({}))
  properties_map   = merge(local.base_properties, { availability = local.availability_map }, local.properties_map_enb) #build the properties map
  #merge the extended network Blocks value into the properties if it exists
  properties_map_enb = jsondecode((length(var.extended_network_blocks) == 0) ? jsonencode({}) : jsonencode({ extendedNetworkBlocks = var.extended_network_blocks }))
  secondary_zone_map = jsondecode(var.secondary_zone != null ? jsonencode({ secondaryZone = var.secondary_zone }) : jsonencode({}))
}

#build a base private cloud resource then modify it as needed.
resource "azapi_resource" "this_private_cloud" {
  location                  = var.location
  name                      = var.name
  parent_id                 = var.resource_group_resource_id
  type                      = "Microsoft.AVS/privateClouds@2025-09-01"
  body                      = local.full_body
  ignore_casing             = true
  ignore_missing_property   = true
  ignore_null_property      = true
  response_export_values    = ["*"]
  schema_validation_enabled = false
  tags                      = var.tags

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned

    content {
      type = identity.value.type
    }
  }

  #TODO: Test to see if a lifecycle block is needed when the NSXT or VCenter passwords change
  timeouts {
    create = "15h"
    delete = "4h"
  }

  lifecycle {
    ignore_changes = [body.properties.nsxtPassword, body.properties.vcenterPassword, body.properties.managementCluster.hosts, body.properties.availability.zone]
  }
}

resource "azapi_resource" "vcf_firewall_license" {
  count = var.vcf_firewall_license != null ? 1 : 0

  name                   = "VmwareFirewall"
  parent_id              = azapi_resource.this_private_cloud.id
  type                   = "Microsoft.AVS/privateClouds/licenses@2025-09-01"
  body                   = { properties = var.vcf_firewall_license }
  replace_triggers_refs  = ["body.properties"]
  response_export_values = ["*"]

  depends_on = [azapi_resource.this_private_cloud]
}

#use a data resource to get the identity details to avoid terraform import issues
data "azapi_resource" "this_private_cloud" {
  resource_id            = azapi_resource.this_private_cloud.id
  type                   = "Microsoft.AVS/privateClouds@2025-09-01"
  response_export_values = ["*"]

  depends_on = [azapi_resource.this_private_cloud]
}
