module "naming" {
  source  = "Azure/naming/azurerm"
  version = "= 0.4.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "= 0.5.2"
}

locals {
  dc_vm_sku             = "Standard_D2_v4"
  ldap_user_name        = "ldapuser"
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
  total_quota_required = 3
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

resource "azurerm_resource_group" "this_secondary" {
  location = "westus3" #module.regions.regions_by_name[jsondecode(local_file.region_sku_cache.content).name].paired_region_name
  name     = "${module.naming.resource_group.name_unique}-secondary"

  lifecycle {
    ignore_changes = [tags, location]
  }
}

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.5.3"

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

module "gateway_vnet_primary_region" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.1.4"

  resource_group_name           = azurerm_resource_group.this.name
  virtual_network_address_space = ["10.100.0.0/16"]
  name                          = "HubVnet-${azurerm_resource_group.this.location}"
  location                      = azurerm_resource_group.this.location

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
    ElasticSanSubnet = {
      address_prefixes = ["10.100.4.0/24"]
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

module "gateway_vnet_secondary_region" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.1.4"

  resource_group_name           = azurerm_resource_group.this_secondary.name
  virtual_network_address_space = ["10.101.0.0/16"]
  name                          = "HubVnet-${azurerm_resource_group.this_secondary.location}-2"
  location                      = azurerm_resource_group.this_secondary.location

  subnets = {
    GatewaySubnet = {
      address_prefixes = ["10.101.0.0/24"]
    }
    DCSubnet = {
      address_prefixes = ["10.101.1.0/24"]
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.101.2.0/24"]
    }
    ElasticSanSubnet = {
      address_prefixes = ["10.101.4.0/24"]
    }
    ANFSubnet = {
      address_prefixes = ["10.101.3.0/24"]
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
  #source = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/create_test_domain_controllers"

  resource_group_name         = azurerm_resource_group.this.name
  resource_group_location     = azurerm_resource_group.this.location
  dc_vm_name                  = "dc01-${module.naming.virtual_machine.name_unique}"
  dc_vm_name_secondary        = "dc02-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id       = module.avm_res_keyvault_vault.resource.id
  create_bastion              = true
  bastion_name                = module.naming.bastion_host.name_unique
  bastion_pip_name            = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id  = module.gateway_vnet_primary_region.subnets["AzureBastionSubnet"].id
  dc_subnet_resource_id       = module.gateway_vnet_primary_region.subnets["DCSubnet"].id
  dc_vm_sku                   = local.dc_vm_sku
  domain_fqdn                 = local.test_domain_name
  domain_netbios_name         = local.test_domain_netbios
  domain_distinguished_name   = local.test_domain_dn
  ldap_user                   = local.ldap_user_name
  test_admin_user             = local.test_admin_user_name
  admin_group_name            = local.test_admin_group_name
  private_ip_address          = cidrhost("10.100.1.0/24", 4)
  virtual_network_resource_id = module.gateway_vnet_primary_region.vnet_resource.id

  depends_on = [module.avm_res_keyvault_vault, module.gateway_vnet_primary_region, azurerm_nat_gateway.this_nat_gateway]
}


resource "azurerm_log_analytics_workspace" "this_workspace" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

resource "azurerm_public_ip" "gatewaypip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard" #required for an ultraperformance gateway
  zones               = ["1", "2", "3"]
}

resource "azurerm_virtual_network_gateway" "gateway" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.express_route_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "ErGw1AZ"
  type                = "ExpressRoute"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.gatewaypip.id
    subnet_id                     = module.gateway_vnet_primary_region.subnets["GatewaySubnet"].id
    name                          = "default"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "gatewaypip_secondary" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this_secondary.location
  name                = "${module.naming.public_ip.name_unique}-secondary"
  resource_group_name = azurerm_resource_group.this_secondary.name
  sku                 = "Standard" #required for an ultraperformance gateway
  zones               = ["1", "2", "3"]
}

resource "azurerm_virtual_network_gateway" "gateway_secondary" {
  location            = azurerm_resource_group.this_secondary.location
  name                = "${module.naming.express_route_gateway.name_unique}-secondary"
  resource_group_name = azurerm_resource_group.this_secondary.name
  sku                 = "ErGw1AZ"
  type                = "ExpressRoute"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.gatewaypip_secondary.id
    subnet_id                     = module.gateway_vnet_secondary_region.subnets["GatewaySubnet"].id
    name                          = "default"
    private_ip_address_allocation = "Dynamic"
  }
}

module "create_anf_volume" {
  source = "../../modules/create_test_netapp_volume"
  #source = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/create_test_netapp_volume"

  resource_group_name     = azurerm_resource_group.this.name
  resource_group_location = azurerm_resource_group.this.location
  anf_account_name        = "anf-${module.naming.storage_share.name_unique}"
  anf_pool_name           = "anf-pool-${module.naming.storage_share.name_unique}"
  anf_pool_size           = 2
  anf_volume_name         = "anf-volume-${module.naming.storage_share.name_unique}"
  anf_volume_size         = 2048
  anf_subnet_resource_id  = module.gateway_vnet_primary_region.subnets["ANFSubnet"].id
  anf_zone_number         = module.test_private_cloud.resource.properties.availability.zone
  anf_nfs_allowed_clients = ["0.0.0.0/0"]
}


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
          esan_subnet_resource_id              = module.gateway_vnet_primary_region.subnets["ElasticSanSubnet"].id
          private_link_service_connection_name = "esan-${module.naming.private_service_connection.name_unique}"
        }
      }
    }
  }
}

module "test_private_cloud" {
  source = "../../"
  # source             = "Azure/avm-res-avs-privatecloud/azurerm"
  # version            = "=0.7.0"

  enable_telemetry               = var.enable_telemetry
  resource_group_name            = azurerm_resource_group.this.name
  location                       = azurerm_resource_group.this.location
  resource_group_resource_id     = azurerm_resource_group.this.id
  name                           = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  sku_name                       = jsondecode(local_file.region_sku_cache.content).sku
  avs_network_cidr               = "10.0.0.0/22"
  internet_enabled               = true
  management_cluster_size        = 3
  extended_network_blocks        = ["10.10.0.0/23"]
  external_storage_address_block = "10.20.0.0/24"

  addons = {
    HCX = {
      hcx_key_names    = ["example_key_1", "example_key_2"]
      hcx_license_type = "Enterprise"
    }
  }

  /* example for adding additional clusters
  clusters = {
    "Cluster-2" = {
      cluster_node_count = 3
      sku_name           = jsondecode(local_file.region_sku_cache.content).sku
    }
  }
  */

  customer_managed_key = {
    key_vault_resource_id = module.avm_res_keyvault_vault.resource.id
    key_name              = module.avm_res_keyvault_vault.resource_keys.cmk_key.name
    key_version           = module.avm_res_keyvault_vault.resource_keys.cmk_key.version
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

  elastic_san_datastores = {
    esan_datastore_cluster1 = {
      esan_volume_resource_id = module.elastic_san.volumes["vg_1-volume_1"].id
      cluster_names           = ["Cluster-1"]
    }
  }

  expressroute_connections = {
    region1 = {
      name                             = "exr-connection-${azurerm_resource_group.this.location}"
      expressroute_gateway_resource_id = azurerm_virtual_network_gateway.gateway.id
      authorization_key_name           = "test_auth_key-${azurerm_resource_group.this.location}"
    }
    region2 = {
      name                               = "exr-connection-${azurerm_resource_group.this_secondary.location}"
      expressroute_gateway_resource_id   = azurerm_virtual_network_gateway.gateway_secondary.id
      authorization_key_name             = "test_auth_key-${azurerm_resource_group.this_secondary.location}"
      network_resource_group_resource_id = azurerm_resource_group.this_secondary.id
      network_resource_group_location    = azurerm_resource_group.this_secondary.location
    }
  }

  /*Example global reach connection.  Uncomment and provide the target auth key and circuit id to create a new GR circuit
  global_reach_connections = {
    gr_region_1 = {
      authorization_key                     = "00000000-0000-0000-0000-000000000000"
      peer_expressroute_circuit_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<resource_group_name>/providers/Microsoft.Network/expressRouteCircuits/tnt##-cust-p##-region-er"
    }
  }
  */

  lock = {
    name = "lock-avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
    kind = "CanNotDelete"
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
    scenario = "avs_full_example"
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
}
