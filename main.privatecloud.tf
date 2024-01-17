#defaulting to azAPI for private cloud provisioning due to issues with feature lag on AzureRM for AVS
#and need to avoid breaking changes

#build a base private cloud resource then modify it as needed.
resource "azapi_resource" "this_private_cloud" {

  type      = "Microsoft.AVS/privateClouds@2022-05-01"
  name      = var.name
  parent_id = data.azurerm_resource_group.sddc_deployment.id
  location  = local.location
  tags      = var.tags


  body = jsonencode({
    sku = {
      name = lower(var.sku_name)
    }
    properties = {
      managementCluster = {
        clusterSize = var.management_cluster_size
      }

      networkBlock    = var.avs_network_cidr
      nsxtPassword    = local.nsxt_password
      vcenterPassword = local.vcenter_password
      internet        = var.internet_enabled ? "Enabled" : "Disabled"

      availability = {
        secondaryZone = var.secondary_zone
        zone          = var.primary_zone
        strategy      = var.enable_stretch_cluster ? "DualZone" : "SingleZone"
      }
    }
  })

  #TODO: Test to see if a lifecycle block is needed when the NSXT or VCenter passwords change
  timeouts {
    create = "15h"
    delete = "4h"
    update = "4h"
  }

  response_export_values = ["*"]
  #ignore_body_changes = ["properties.nsxtPassword", "properties.vcenterPassword"] #don't try to recreate the private cloud if the passwords change

}
