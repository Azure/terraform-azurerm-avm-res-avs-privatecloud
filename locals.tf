# TODO: insert locals here.
locals {
  #set the resource deployment location. Default to the resource group location
  location         = coalesce(var.location, data.azurerm_resource_group.sddc_deployment.location)
  nsxt_password    = coalesce(var.nsxt_password, random_password.nsxt.result)
  vcenter_password = coalesce(var.vcenter_password, random_password.vcenter.result)

}


