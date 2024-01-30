#get the resource group information 
data "azurerm_resource_group" "sddc_deployment" {
  name = var.resource_group_name
}
