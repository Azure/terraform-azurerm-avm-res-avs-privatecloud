terraform {
  required_version = "~>1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.9.0"
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

locals {
  vm_sku = "Standard_D2_v4"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "=0.3.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "=0.4.0"
}

data "azurerm_client_config" "current" {}

module "generate_deployment_region" {
  source               = "../../modules/generate_deployment_region"
  total_quota_required = 3
}

resource "local_file" "region_sku_cache" {
  content  = jsonencode(module.generate_deployment_region.deployment_region)
  filename = "${path.module}/region_cache.cache"
  lifecycle {
    ignore_changes = [content]
  }
}

resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = jsondecode(local_file.region_sku_cache.content).name

  lifecycle {
    ignore_changes = [tags, location]
  }
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "${module.naming.nat_gateway.name_unique}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this_nat_gateway" {
  name                = module.naming.nat_gateway.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this_nat_gateway" {
  nat_gateway_id       = azurerm_nat_gateway.this_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

module "gateway_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.1.3"

  resource_group_name           = azurerm_resource_group.this.name
  virtual_network_address_space = ["10.100.0.0/16"]
  vnet_name                     = "GatewayHubVnet"
  vnet_location                 = azurerm_resource_group.this.location

  subnets = {
    GatewaySubnet = {
      address_prefixes = ["10.100.0.0/24"]
    }
    VMSubnet = {
      address_prefixes = ["10.100.1.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.this_nat_gateway.id
      }
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.100.2.0/24"]
    }
  }
}

resource "azurerm_log_analytics_workspace" "this_workspace" {
  name                = module.naming.log_analytics_workspace.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_public_ip" "gatewaypip" {
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = module.naming.express_route_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type = "ExpressRoute"
  sku  = "ErGw1AZ"

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.gatewaypip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.gateway_vnet.subnets["GatewaySubnet"].id
  }
}

module "avm-res-keyvault-vault" {
  source                 = "Azure/avm-res-keyvault-vault/azurerm"
  version                = "=0.5.1"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  name                   = module.naming.key_vault.name_unique
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  enabled_for_deployment = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}

module "test_private_cloud" {
  source = "../../"
  # source             = "Azure/avm-res-avs-privatecloud/azurerm"
  # version            = "=0.1.0"

  enable_telemetry        = var.enable_telemetry
  resource_group_name     = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  name                    = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  sku_name                = jsondecode(local_file.region_sku_cache.content).sku
  avs_network_cidr        = "10.0.0.0/22"
  internet_enabled        = false
  management_cluster_size = 3
  hcx_enabled             = true
  hcx_key_names           = ["test_site_key_1"]

  diagnostic_settings = {
    avs_diags = {
      name                  = module.naming.monitor_diagnostic_setting.name_unique
      workspace_resource_id = azurerm_log_analytics_workspace.this_workspace.id
      metric_categories     = ["AllMetrics"]
      log_groups            = ["allLogs"]
    }
  }

  expressroute_connections = {
    default = {
      authorization_key_name           = "test_auth_key"
      expressroute_gateway_resource_id = azurerm_virtual_network_gateway.gateway.id
    }
  }

  tags = {
    scenario = "avs_default_vnet"
  }
}

module "create_jump_vm" {
  source = "../../modules/create_jump_vm"

  resource_group_name        = azurerm_resource_group.this.name
  resource_group_location    = azurerm_resource_group.this.location
  vm_name                    = "jump-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id      = module.avm-res-keyvault-vault.resource.id
  create_bastion             = true
  bastion_name               = module.naming.bastion_host.name_unique
  bastion_pip_name           = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id = module.gateway_vnet.subnets["AzureBastionSubnet"].id
  vm_subnet_resource_id      = module.gateway_vnet.subnets["VMSubnet"].id
  vm_sku                     = local.vm_sku

  depends_on = [module.avm-res-keyvault-vault, module.gateway_vnet, azurerm_nat_gateway.this_nat_gateway]
}
