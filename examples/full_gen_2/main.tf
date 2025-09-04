module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.0"

  availability_zones_filter = true
}

locals {
  #dc_vm_sku             = "Standard_D2s_v6"
  ldap_user_name        = "ldapuser"
  location_zone         = 3
  test_admin_group_name = "vcenterAdmins"
  test_admin_user_name  = "testadmin"
  test_domain_dn        = "dc=test,dc=local"
  test_domain_name      = "test.local"
  test_domain_netbios   = "test"
}

data "azurerm_client_config" "current" {}

module "generate_deployment_region" {
  source = "../../modules/generate_deployment_region"

  #source               = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/generate_deployment_region"
  management_cluster_quota_required = 3
  private_cloud_generation          = 2
  secondary_cluster_quota_required  = 3
  test_regions = [
    "australiaeast",
    "brazilsouth",
    "centralindia",
    "centralus",
    "eastasia",
    "eastus",
    "eastus2",
    "francecentral",
    "germanywestcentral",
    "italynorth",
    "japaneast",
    "japanwest",
    "northeurope",
    "qatarcentral",
    "southafricanorth",
    "southcentralus",
    "southeastasia",
    "swedencentral",
    "switzerlandnorth",
    "uaenorth",
    "uksouth",
    "westeurope",
    "westus2",
    "westus3"
  ]
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

module "vm_sku" {
  source  = "Azure/avm-utl-sku-finder/azapi"
  version = "0.3.0"

  location      = azurerm_resource_group.this.location
  cache_results = true
  vm_filters = {
    min_vcpus                      = 2
    max_vcpus                      = 2
    encryption_at_host_supported   = true
    accelerated_networking_enabled = true
    cpu_architecture_type          = "x64"
    low_priority_capable           = true
  }
}

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location               = azurerm_resource_group.this.location
  name                   = module.naming.key_vault.name_unique
  resource_group_name    = azurerm_resource_group.this.name
  tenant_id              = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment = true
  keys = {
    "cmk-disk-key" = {
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
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
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
      principal_id               = module.test_private_cloud.identity.principalId
    }
  }
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}

data "azurerm_key_vault_key" "cmk_key" {
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  name         = split("/", module.avm_res_keyvault_vault.keys["cmk-disk-key"].resource_id)[10]
}

module "avs_vnet_primary_region" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  address_space       = ["10.100.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  name                = "HubVnet-${azurerm_resource_group.this.location}"
  subnets = {
    DCSubnet = {
      name             = "DCSubnet"
      address_prefixes = ["10.100.1.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.this_nat_gateway.id
      }
    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.100.2.0/24"]
    }
    ElasticSanSubnet = {
      name             = "ElasticSanSubnet"
      address_prefixes = ["10.100.4.0/24"]
    }
    ANFSubnet = {
      name             = "ANFSubnet"
      address_prefixes = ["10.100.3.0/24"]
      delegation = [
        {
          name = "Microsoft.Netapp/volumes"
          service_delegation = {
            name = "Microsoft.Netapp/volumes"
          }
        }
      ]
    }
  }
}

resource "azurerm_public_ip" "nat_gateway" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.nat_gateway.name_unique}-pip"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_nat_gateway" "this_nat_gateway" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.nat_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this_nat_gateway" {
  nat_gateway_id       = azurerm_nat_gateway.this_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

module "create_dc" {
  source = "../../modules/create_test_domain_controllers"

  dc_subnet_resource_id       = module.avs_vnet_primary_region.subnets["DCSubnet"].resource_id
  dc_vm_name                  = "dc01-${module.naming.virtual_machine.name_unique}"
  dc_vm_name_secondary        = "dc02-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id       = module.avm_res_keyvault_vault.resource_id
  private_ip_address          = cidrhost("10.100.1.0/24", 4)
  resource_group_location     = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  virtual_network_resource_id = module.avs_vnet_primary_region.resource_id
  admin_group_name            = local.test_admin_group_name
  bastion_name                = module.naming.bastion_host.name_unique
  bastion_pip_name            = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id  = module.avs_vnet_primary_region.subnets["AzureBastionSubnet"].resource_id
  create_bastion              = true
  #dc_vm_sku                   = module.vm_sku.sku
  dc_vm_sku                 = "Standard_D2s_v3"
  domain_distinguished_name = local.test_domain_dn
  domain_fqdn               = local.test_domain_name
  domain_netbios_name       = local.test_domain_netbios
  ldap_user                 = local.ldap_user_name
  test_admin_user           = local.test_admin_user_name

  depends_on = [module.avm_res_keyvault_vault, module.avs_vnet_primary_region, azurerm_nat_gateway.this_nat_gateway]
}


resource "azurerm_log_analytics_workspace" "this_workspace" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "create_anf_volume" {
  source = "../../modules/create_test_netapp_volume"

  anf_account_name        = "anf-${module.naming.storage_share.name_unique}"
  anf_nfs_allowed_clients = ["0.0.0.0/0"]
  anf_pool_name           = "anf-pool-${module.naming.storage_share.name_unique}"
  anf_pool_size           = 4
  anf_subnet_resource_id  = module.avs_vnet_primary_region.subnets["ANFSubnet"].resource_id
  anf_volume_name         = "anf-volume-${module.naming.storage_share.name_unique}"
  anf_volume_size         = 4096
  anf_zone_number         = module.test_private_cloud.resource.properties.availability.zone
  resource_group_location = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
}

/* #Elastic SAN is not currently supported in the Gen 2 public preview.  
module "elastic_san" {
  source = "../../modules/create_elastic_san_volume"
  #source                = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/create_elastic_san_volume"
  elastic_san_name      = "esan-${module.naming.storage_share.name_unique}"
  resource_group_id     = azurerm_resource_group.this.id
  location              = azurerm_resource_group.this.location
  base_size_in_tib      = 1
  extended_size_in_tib  = 1
  zones                 = [module.test_private_cloud.resource.properties.availability.zone]
  public_network_access = "Enabled"

  sku = {
    name = "Premium_LRS"
    tier = "Premium"
  }

  elastic_san_volume_groups = {
    vg_1 = {
      name          = "esan-vg-${module.naming.storage_share.name_unique}"
      protocol_type = "iSCSI"
      volumes = {
        volume_1 = {
          name        = "esan-vol-${module.naming.storage_share.name_unique}-01"
          size_in_gib = 100
        }
      }

      private_link_service_connections = {
        pls_conn_1 = {
          private_endpoint_name                = "esan-${module.naming.private_endpoint.name_unique}"
          resource_group_name                  = azurerm_resource_group.this.name
          resource_group_location              = azurerm_resource_group.this.location
          esan_subnet_resource_id              = module.avs_vnet_primary_region.subnets["ElasticSanSubnet"].resource_id
          private_link_service_connection_name = "esan-${module.naming.private_service_connection.name_unique}"
        }
      }
    }
  }
}
*/

# create the virtual network for the avs private cloud 
# this is required since the gen 2 AVS private cloud manages the subnets
resource "azurerm_virtual_network" "avs_vnet_primary_region" {
  location            = azurerm_resource_group.this.location
  name                = "AVSVnet-${azurerm_resource_group.this.location}"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.200.0.0/16"]
}
/* test this first
resource "azurerm_public_ip" "nat_gateway_avs" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.nat_gateway.name_unique}-pip-avs"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_nat_gateway" "this_nat_gateway_avs" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.nat_gateway.name_unique}-avs"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}
*/

#peer to the hub vnet
module "peering" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "0.8.1"

  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
  create_reverse_peering       = true
  name                         = "${module.naming.virtual_network_peering.name_unique}-avs-to-hub"
  remote_virtual_network = {
    resource_id = module.avs_vnet_primary_region.resource_id
  }
  reverse_allow_forwarded_traffic      = false
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_name                         = "${module.naming.virtual_network_peering.name_unique}-hub-to-avs"
  reverse_use_remote_gateways          = false
  use_remote_gateways                  = false
  virtual_network = {
    resource_id = azurerm_virtual_network.avs_vnet_primary_region.id
  }
}

module "test_private_cloud" {
  source = "../../"

  avs_network_cidr           = "10.200.0.0/22"
  location                   = azurerm_resource_group.this.location
  name                       = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  resource_group_name        = azurerm_resource_group.this.name
  resource_group_resource_id = azurerm_resource_group.this.id
  sku_name                   = jsondecode(local_file.region_sku_cache.content).sku-mgmt
  addons = {
    HCX = {
      hcx_key_names          = ["example_key_1", "example_key_2"]
      hcx_license_type       = "Enterprise"
      hcx_management_network = "192.168.0.0/24"
      hcx_uplink_network     = "192.168.1.0/24"
    }
  }
  #example for adding additional clusters
  clusters = {
    "Cluster-2" = {
      cluster_node_count = 3
      sku_name           = jsondecode(local_file.region_sku_cache.content).sku-sec
    }
  }
  customer_managed_key = {
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
    key_name              = data.azurerm_key_vault_key.cmk_key.name
    key_version           = data.azurerm_key_vault_key.cmk_key.version
  }
  dhcp_configuration = {
    server_config = {
      display_name      = "test_dhcp"
      dhcp_type         = "SERVER"
      server_lease_time = 14400
      server_address    = "10.201.0.1/24"
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
  dns_zone_type    = "Private"
  enable_telemetry = var.enable_telemetry
  internet_enabled = false
  lock = {
    name = "lock-avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
    kind = "CanNotDelete"
  }
  managed_identities = {
    system_assigned = true
  }
  management_cluster_size = 3
  netapp_files_datastores = {
    anf_datastore_cluster1 = {
      netapp_volume_resource_id = module.create_anf_volume.volume_id
      cluster_names             = ["Cluster-1"]
    }
  }
  role_assignments = {
    deployment_user_contributor = {
      role_definition_id_or_name = "Contributor"
      principal_id               = data.azurerm_client_config.current.client_id
      principal_type             = "ServicePrincipal"
    }
  }
  segments = {
    segment_1 = {
      display_name    = "segment_1"
      gateway_address = "10.20.0.1/24"
      dhcp_ranges     = ["10.20.0.5-10.20.0.100"]
    }
    segment_2 = {
      display_name    = "segment_2"
      gateway_address = "10.30.0.1/24"
    }
  }
  tags = {
    scenario = "avs_full_example_gen_2"
  }
  vcenter_identity_sources = {
    test_local = {
      alias          = module.create_dc.domain_netbios_name
      base_group_dn  = module.create_dc.domain_distinguished_name
      base_user_dn   = module.create_dc.domain_distinguished_name
      domain         = module.create_dc.domain_fqdn
      group_name     = "vcenterAdmins"
      name           = module.create_dc.domain_fqdn
      primary_server = "ldaps://${module.create_dc.dc_details.name}.${module.create_dc.domain_fqdn}:636"
      #secondary_server = "ldaps://${module.create_dc.dc_details_secondary.name}.${module.create_dc.domain_fqdn}:636"
      ssl = "Enabled"
    }
  }
  vcenter_identity_sources_credentials = {
    test_local = {
      ldap_user          = module.create_dc.ldap_user
      ldap_user_password = module.create_dc.ldap_user_password
    }
  }
  virtual_network_resource_id = azurerm_virtual_network.avs_vnet_primary_region.id
}
