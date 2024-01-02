terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">=1.9.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.4.0"
}

#seed the test regions with regions where the lab subscription currently has quota
locals {
  test_regions = ["southafricanorth", "eastasia", "canadacentral"]
}

### this segment of code gets quota availability for testing
data "azurerm_subscription" "current" {
}

#query the quota api for each test region
data "azapi_resource_action" "quota" {
  for_each = toset(local.test_regions)

  type                   = "Microsoft.AVS/locations@2023-03-01"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.AVS/locations/${each.key}"
  method                 = "POST"
  action                 = "checkQuotaAvailability"
  response_export_values = ["hostsRemaining"]
}

#generate a list of regions with at least 3 quota for deployment
locals {
  with_quota = [for region in data.azapi_resource_action.quota : split("/", region.resource_id)[6] if jsondecode(region.output).hostsRemaining.he >= 6]
}

resource "random_integer" "region_index" {
  count = length(local.with_quota) > 0 ? 1 : 0 #fails if we don't have quota

  min = 0
  max = length(local.with_quota) - 1
}

resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  count = length(local.with_quota) > 0 ? 1 : 0 #fails if we don't have quota

  name     = module.naming.resource_group.name_unique
  location = local.with_quota[random_integer.region_index[0].result]
}

#create a simple vnet for the expressroute gateway
module "gateway_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = ">=0.1.3"

  resource_group_name           = azurerm_resource_group.this[0].name
  virtual_network_address_space = ["10.100.0.0/16"]
  vnet_name                     = "GatewayHubVnet"
  vnet_location                 = azurerm_resource_group.this[0].location
  subnets = {
    GatewaySubnet = {
      address_prefixes = ["10.100.0.0/24"]
    }
  }
}

#Create a public IP
resource "azurerm_public_ip" "gatewaypip" {
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this[0].name
  location            = azurerm_resource_group.this[0].location
  allocation_method   = "Static"
  sku                 = "Standard" #required for an ultraperformance gateway

}

#create an expressRoute gateway
resource "azurerm_virtual_network_gateway" "gateway" {
  name                = module.naming.express_route_gateway.name_unique
  resource_group_name = azurerm_resource_group.this[0].name
  location            = azurerm_resource_group.this[0].location

  type = "ExpressRoute"
  sku  = "ErGw1AZ"

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.gatewaypip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.gateway_vnet.subnets["GatewaySubnet"].id
  }
}

# Create the private cloud and connect it to a vnet expressroute gateway
module "test_private_cloud" {
  source = "../../"
  # source             = "Azure/avm-res-avs-privatecloud/azurerm"

  count = length(local.with_quota) > 0 ? 1 : 0 #fails if we don't have quota

  enable_telemetry        = var.enable_telemetry
  resource_group_name     = azurerm_resource_group.this[0].name
  location                = azurerm_resource_group.this[0].location
  name                    = "avs-sddc-${random_string.namestring.result}"
  sku_name                = "av36"
  avs_network_cidr        = "10.0.0.0/22"
  internet_enabled        = false
  management_cluster_size = 3
  hcx_enabled             = true
  hcx_key_names           = ["test_site_key_1"] #requires the HCX addon to be configured

  #define the expressroute connections
  expressroute_connections = {
    default = {
      expressroute_gateway_resource_id = azurerm_virtual_network_gateway.gateway.id
    }
  }

  #define the clusters
  clusters = {
    Cluster_2 = {
      cluster_node_count = 3
      sku_name           = "av36"
    }
  }

  #define the tags
  tags = {
    scenario = "avs_sddc_default"
  }
}

#export the cloudadmin credentials for use in vmware centered automation
output "cloudadmin_creds" {
  value     = module.test_private_cloud.0.credentials
  sensitive = true
}


