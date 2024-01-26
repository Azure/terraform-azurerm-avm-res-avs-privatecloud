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
      version = "~> 1.12"
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

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "= 0.4.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "= 0.4.0"
}

locals {
  test_domain_name    = "test.local"
  test_domain_netbios = "test"
  test_domain_dn      = "dc=test,dc=local"
  ldap_user_name      = "ldapuser"
  test_admin_user_name = "testadmin"
  test_admin_group_name = "vcenterAdmins"
  dc_vm_sku           = "Standard_D2_v4"
}

data "azurerm_client_config" "current" {}

module "generate_deployment_region" {
  source               = "../../modules/generate_deployment_region"
  total_quota_required = 6
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

module "avm-res-keyvault-vault" {
  source                 = "Azure/avm-res-keyvault-vault/azurerm"
  version                = ">=0.3.0"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  name                   = module.naming.key_vault.name_unique
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  enabled_for_deployment = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  keys = {
    cmk_key = {
      name     = "cmk-disk-key"
      key_type = "RSA"
      key_size = 2048

      key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey",
      ]
    }
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_user_keys = { #give the deployment user access to keys
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    system_managed_identity_keys = { #give the system assigned managed identity for the disk encryption set access to keys
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = module.test_private_cloud.identity.identity.principalId
    }
  }

  wait_for_rbac_before_key_operations = {
    create = "60s"
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
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
    DCSubnet = {
      address_prefixes = ["10.100.1.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.this_nat_gateway.id
      }
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.100.2.0/24"]
    }
    ANFSubnet = {
      address_prefixes = ["10.100.3.0/24"]
      delegations = [
        {
          name = "Microsoft.Netapp/volumes"
          service_delegation = {
            name = "Microsoft.Netapp/volumes"
            actions = [
              "Microsoft.Network/networkinterfaces/*",
              "Microsoft.Network/virtualNetworks/subnets/join/action"
            ]
          }
        }
      ]
    }
  }
}

module "create_dc" {
  source = "../../modules/create_test_domain_controllers"

  resource_group_name         = azurerm_resource_group.this.name
  resource_group_location     = azurerm_resource_group.this.location
  dc_vm_name                  = "dc01-${module.naming.virtual_machine.name_unique}"
  dc_vm_name_secondary        = "dc02-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id       = module.avm-res-keyvault-vault.resource.id
  create_bastion              = true
  bastion_name                = module.naming.bastion_host.name_unique
  bastion_pip_name            = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id  = module.gateway_vnet.subnets["AzureBastionSubnet"].id
  dc_subnet_resource_id       = module.gateway_vnet.subnets["DCSubnet"].id
  dc_vm_sku                   = local.dc_vm_sku
  domain_fqdn                 = local.test_domain_name
  domain_netbios_name         = local.test_domain_netbios
  domain_distinguished_name   = local.test_domain_dn
  ldap_user                   = local.ldap_user_name
  test_admin_user             = local.test_admin_user_name
  admin_group_name            = local.test_admin_group_name
  private_ip_address          = cidrhost("10.100.1.0/24", 4)
  virtual_network_resource_id = module.gateway_vnet.vnet-resource.id

  depends_on = [module.avm-res-keyvault-vault, module.gateway_vnet, azurerm_nat_gateway.this_nat_gateway]
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
  sku                 = "Standard" #required for an ultraperformance gateway

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

module "create_anf_volume" {
  source = "../../modules/create_test_netapp_volume"

  resource_group_name     = azurerm_resource_group.this.name
  resource_group_location = azurerm_resource_group.this.location
  anf_account_name        = "anf-${module.naming.storage_share.name_unique}"
  anf_pool_name           = "anf-pool-${module.naming.storage_share.name_unique}"
  anf_pool_size           = 2
  anf_volume_name         = "anf-volume-${module.naming.storage_share.name_unique}"
  anf_volume_size         = 2048
  anf_subnet_resource_id  = module.gateway_vnet.subnets["ANFSubnet"].id
  anf_zone_number         = module.test_private_cloud.private_cloud.properties.availability.zone
  anf_nfs_allowed_clients = ["0.0.0.0/0"]
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
  internet_enabled        = true
  management_cluster_size = 3
  hcx_enabled             = true
  hcx_key_names           = ["test_site_key_1"]
  ldap_user               = "${module.create_dc.ldap_user}@${module.create_dc.domain_fqdn}"
  ldap_user_password      = module.create_dc.ldap_user_password

  clusters = {
    Cluster_2 = {
      cluster_node_count = 3
      sku_name           = jsondecode(local_file.region_sku_cache.content).sku
    }
  }

  customer_managed_key = {
    key_vault_resource_id = module.avm-res-keyvault-vault.resource.id
    key_name              = module.avm-res-keyvault-vault.resource_keys.cmk_key.name
    key_version           = module.avm-res-keyvault-vault.resource_keys.cmk_key.version
  }

  dhcp_configuration = {
    server_config = {
      display_name      = "test_dhcp"
      dhcp_type         = "SERVER"
      server_lease_time = 14400
      server_address    = "10.101.0.1/24"
    }
  }

  diagnostic_settings = {
    avs_diags = {
      name                  = module.naming.monitor_diagnostic_setting.name_unique
      workspace_resource_id = azurerm_log_analytics_workspace.this_workspace.id
      metric_categories     = ["AllMetrics"]
      log_groups            = ["allLogs"]
    }
  }

  
  dns_forwarder_zones = {
    test_local = {
      display_name               = local.test_domain_name
      dns_server_ips             = [module.create_dc.dc_details.private_ip_address]
      domain_names               = [module.create_dc.domain_fqdn]
      add_to_default_dns_service = true
    }
  }
  

  expressroute_connections = {
    default = {
      expressroute_gateway_resource_id = azurerm_virtual_network_gateway.gateway.id
      authorization_key_name           = "test_auth_key"
    }
  }

  lock = {
    name = "lock-avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
    type = "CanNotDelete"
  }

  managed_identities = {
    system_assigned = true
  }

  netapp_files_datastores = {
    anf_datastore_cluster1 = {
      netapp_volume_resource_id = module.create_anf_volume.volume_id
      cluster_names             = ["Cluster-1"]
    }
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Contributor"
      principal_id               = data.azurerm_client_config.current.client_id
    }
  }

  segments = {
    segment_1 = {
      display_name    = "segment_5"
      gateway_address = "10.20.0.1/24"
      dhcp_ranges     = ["10.20.0.5-10.20.0.100"]
    }
    segment_2 = {
      display_name    = "segment_2"
      gateway_address = "10.30.0.1/24"
    }
  }

  tags = {
    scenario = "avs_full_example"
  }

  
  vcenter_identity_sources = {
    test_local = {
      alias            = module.create_dc.domain_netbios_name
      base_group_dn    = module.create_dc.domain_distinguished_name
      base_user_dn     = module.create_dc.domain_distinguished_name
      domain           = module.create_dc.domain_fqdn
      #group_name       = "Domain Users"
      group_name        = "vcenterAdmins"
      name             = module.create_dc.domain_fqdn
      primary_server   = "ldaps://${module.create_dc.dc_details.name}.${module.create_dc.domain_fqdn}:636"
      secondary_server = "ldaps://${module.create_dc.dc_details_secondary.name}.${module.create_dc.domain_fqdn}:636"
      ssl              = "Enabled"
    }
  }
  
}
