
locals {
  vm_sku = "Standard_D2_v4"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.0"
}

data "azurerm_client_config" "current" {}

module "generate_deployment_region" {
  source = "../../modules/generate_deployment_region"

  #source               = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/generate_deployment_region"
  management_cluster_quota_required = 3
  private_cloud_generation          = 2
  secondary_cluster_quota_required  = 0
  test_regions                      = ["uksouth"]
}

resource "local_file" "region_sku_cache" {
  filename = "${path.module}/region_cache.cache"
  content  = jsonencode(module.generate_deployment_region.deployment_region)

  lifecycle {
    ignore_changes = [content]
  }
}

resource "azurerm_resource_group" "this" {
  location = jsondecode(local_file.region_sku_cache.content).name
  name     = module.naming.resource_group.name_unique

  lifecycle {
    ignore_changes = [tags, location]
  }
}

# create the virtual network for the avs private cloud 
# this is required since the gen 2 AVS private cloud manages the subnets
resource "azurerm_virtual_network" "avs_vnet_primary_region" {
  location            = azurerm_resource_group.this.location
  name                = "AVSVnet-${azurerm_resource_group.this.location}"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.100.0.0/16"]
}

module "test_private_cloud" {
  source = "../../"

  avs_network_cidr           = "10.100.0.0/22"
  location                   = azurerm_resource_group.this.location
  name                       = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  resource_group_name        = azurerm_resource_group.this.name
  resource_group_resource_id = azurerm_resource_group.this.id
  sku_name                   = jsondecode(local_file.region_sku_cache.content).sku-mgmt
  dns_zone_type              = "Public"
  enable_telemetry           = var.enable_telemetry
  internet_enabled           = false
  management_cluster_size    = 3
  tags = {
    scenario = "avs_minimal_gen_2"
  }
  virtual_network_resource_id = azurerm_virtual_network.avs_vnet_primary_region.id
}
