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

#get the deployer user details
data "azurerm_client_config" "current" {}

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
  test_regions     = ["southafricanorth", "eastasia", "canadacentral"]
  test_domain_name = "test.local"
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
  with_quota = [for region in data.azapi_resource_action.quota : split("/", region.resource_id)[6] if jsondecode(region.output).hostsRemaining.he >= 3]
  region = "eastasia"
  install_now = true
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

locals {
  daySecond = (split("-", plantimestamp()))[2]
  month = (split("-", plantimestamp()))[1]
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  #count = length(local.with_quota) > 0 ? 1 : 0 #fails if we don't have quota
  count = local.install_now ? 1 : 0

  name     = module.naming.resource_group.name_unique
  #location = local.with_quota[random_integer.region_index[0].result]
  location = local.region

  tags = {
    DeleteDate = formatdate("MM/DD/YYYY", timestamp())
  }
}


#create a keyvault for storing the credential with RBAC for the deployment user
module "avm-res-keyvault-vault" {
  source                 = "Azure/avm-res-keyvault-vault/azurerm"
  version                = ">=0.3.0"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  name                   = module.naming.key_vault.name_unique
  resource_group_name    = azurerm_resource_group.this[0].name
  location               = azurerm_resource_group.this[0].location
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

#create a NAT gateway and public IP associate it to the Subnet where the DC will be created
resource "azurerm_public_ip" "nat_gateway" {
  name                = "${module.naming.nat_gateway.name_unique}-pip"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this_nat_gateway" {
  name                = module.naming.nat_gateway.name_unique
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this_nat_gateway" {
  nat_gateway_id       = azurerm_nat_gateway.this_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
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
    DCSubnet = {
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

#create DC and Bastion
module "create_dc" {
  source = "../../modules/create_test_domain_controller"

  resource_group_name        = azurerm_resource_group.this[0].name
  resource_group_location    = azurerm_resource_group.this[0].location
  dc_vm_name                 = "dc01-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id      = module.avm-res-keyvault-vault.resource.id
  create_bastion             = true
  bastion_name               = module.naming.bastion_host.name_unique
  bastion_pip_name           = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id = module.gateway_vnet.subnets["AzureBastionSubnet"].id
  dc_subnet_resource_id      = module.gateway_vnet.subnets["DCSubnet"].id
  dc_vm_sku                  = "Standard_D2_v4"
  domain_fqdn                = "test.local"
  domain_netbios_name        = "test"
  domain_distinguished_name  = "dc=test,dc=local"
  ldap_user                  = "ldapuser"

  depends_on = [module.avm-res-keyvault-vault, module.gateway_vnet, azurerm_nat_gateway.this_nat_gateway]
  
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
  name                    = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  sku_name                = "av36"
  avs_network_cidr        = "10.0.0.0/22"
  internet_enabled        = false
  management_cluster_size = 3
  hcx_enabled             = true
  hcx_key_names           = ["test_site_key_1"] #requires the HCX addon to be configured
  ldap_user               = "${module.create_dc.ldap_user}@${module.create_dc.domain_fqdn}"
  ldap_user_password      = module.create_dc.ldap_user_password

  #define the expressroute connections
  expressroute_connections = {
    default = {
      expressroute_gateway_resource_id = azurerm_virtual_network_gateway.gateway.id
    }
  }

  dns_forwarder_zones = {
    test_local = {
      display_name = "test.local"
      dns_server_ips = [module.create_dc.dc_details.private_ip_address]
      domain_names   = [module.create_dc.domain_fqdn]  
      add_to_default_dns_service = true   
    }
    second_domain = {
      display_name = "test2.local"
      dns_server_ips = ["192.168.0.4"]
      domain_names = ["test2.local"]
    }
  }

  #configure the Domain controllers used for Vcenter connectivity
  vcenter_identity_sources = {
    test_local = {
      alias          = module.create_dc.domain_netbios_name
      base_group_dn  = module.create_dc.domain_distinguished_name
      base_user_dn   = module.create_dc.domain_distinguished_name
      domain         = module.create_dc.domain_fqdn
      group_name     = "Domain Users"
      name           = module.create_dc.domain_netbios_name
      primary_server = "ldaps://${module.create_dc.dc_details.name}.${module.create_dc.domain_fqdn}:636"
      ssl            = "Enabled"
    }
  }  

  #define the tags
  tags = {
    scenario = "avs_sddc_ldap"
  }
}

output "dc_values" {
  value     = module.create_dc.dc_details
  sensitive = true
}

output "id" {
    value = module.test_private_cloud[0].id
}
