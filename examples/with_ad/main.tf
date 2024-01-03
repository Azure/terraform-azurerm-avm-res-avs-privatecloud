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


#create a NAT gateway and public IP associate it to the Subnet where the DC will be created
resource "azurerm_public_ip" "nat_gateway" {
  name                = module.naming.public_ip.name_unique
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

resource "azurerm_public_ip" "bastionpip" {
  name                = "${module.naming.public_ip.name_unique}-bastion"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = module.naming.bastion_host.name_unique
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name

  ip_configuration {
    name                 = "${module.naming.bastion_host.name_unique}-ipconf"
    subnet_id            = module.gateway_vnet.subnets["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastionpip.id
  }
}


data "azurerm_client_config" "current" {}

#create a keyvault for storing the credential with RBAC for the deployment user
module "avm-res-keyvault-vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = ">=0.3.0"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this[0].name
  location            = azurerm_resource_group.this[0].location
  enabled_for_deployment = true
  network_acls = {
    default_action = "Allow"
    bypass = "AzureServices"
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

#Create a self-signed certificate for DSC to use for encrypted deployment
resource "azurerm_key_vault_certificate" "this" {
  name         = "${module.naming.key_vault.name_unique}-dsc-cert"
  key_vault_id = module.avm-res-keyvault-vault.resource.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2", "2.5.29.37", "1.3.6.1.4.1.311.80.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["${module.naming.virtual_machine.name_unique}.${local.test_domain_name}"]
      }

      subject            = "CN=${module.naming.virtual_machine.name_unique}"
      validity_in_months = 12
    }
  }
}

#build the DC VM
#create the virtual machine
module "testvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = ">=0.1.0"

  resource_group_name                    = azurerm_resource_group.this[0].name
  virtualmachine_os_type                 = "Windows"
  name                                   = module.naming.virtual_machine.name_unique
  admin_credential_key_vault_resource_id = module.avm-res-keyvault-vault.resource.id
  virtualmachine_sku_size                = "Standard_D2as_v4"

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  managed_identities = {
    system_assigned = true
  }

  network_interfaces = {
    network_interface_1 = {
      name = module.naming.network_interface.name_unique
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = module.gateway_vnet.subnets["DCSubnet"].id
        }
      }
    }
  }

  secrets = [
    {
      key_vault_id = module.avm-res-keyvault-vault.resource.id
      certificate = [
        {
          url   = azurerm_key_vault_certificate.this.secret_id
          store = "My"
        },
        {
          store = "Root"
          url   = azurerm_key_vault_certificate.this.secret_id
        }
      ]
    }
  ]
}
