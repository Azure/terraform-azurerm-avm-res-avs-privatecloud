terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13, != 1.13.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

# tflint-ignore: terraform_module_provider_declaration, terraform_output_separate, terraform_variable_separate
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "= 0.4.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "= 0.5.2"
}

resource "azurerm_resource_group" "this" {
  location = "southafricanorth"
  name     = module.naming.resource_group.name_unique

  lifecycle {
    ignore_changes = [tags, location]
  }
}

module "elastic_san" {
  source               = "../../modules/create_elastic_san_volume"
  elastic_san_name     = "test-elastic-san"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  base_size_in_tib     = 1
  extended_size_in_tib = 1
  zone                 = ["1",]

  sku = {
    name = "Premium_LRS"
    tier = "Premium"
  }

  elastic_san_volume_groups = {
    vg_1 = {
      name          = "esan-test-vg-01"
      protocol_type = "Iscsi"
      volumes = {
        volume_1 = {
          name        = "esan-test-vol-01"
          size_in_gib = 1
        }
      }

        private_link_service_connections = {
            pls_conn_1 = {
                private_endpoint_name = "esan-pe-01"
                resource_group_name = azurerm_resource_group.this.name
                resource_group_location = azurerm_resource_group.this.location
                esan_subnet_resource_id = "/subscriptions/d52f9c4a-5468-47ec-9641-da4ef1916bb5/resourceGroups/rg-g31j/providers/Microsoft.Network/virtualNetworks/GatewayHubVnet/subnets/esanSubnet"
                private_link_service_connection_name = "esan-pls-conn-01"
            }
        }
    }
  }
}