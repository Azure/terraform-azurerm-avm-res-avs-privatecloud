module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.0"
}

module "generate_deployment_region" {
  source = "../../modules/generate_deployment_region"

  #source               = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/generate_deployment_region"
  management_cluster_quota_required = 3
  private_cloud_generation          = 1
  secondary_cluster_quota_required  = 0
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

module "test_private_cloud" {
  source = "../../"

  avs_network_cidr           = "10.100.0.0/22"
  location                   = azurerm_resource_group.this.location
  name                       = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  resource_group_name        = azurerm_resource_group.this.name
  resource_group_resource_id = azurerm_resource_group.this.id
  sku_name                   = jsondecode(local_file.region_sku_cache.content).sku-mgmt
  enable_telemetry           = var.enable_telemetry
  extended_network_blocks    = ["10.100.4.0/23"]
  internet_enabled           = false
  management_cluster_size    = 3
  tags = {
    scenario = "avs_minimal_gen_1"
  }
}
