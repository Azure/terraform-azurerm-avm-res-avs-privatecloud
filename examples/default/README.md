<!-- BEGIN_TF_DOCS -->
# Default AVS example with Vnet ExpressRoute Gateway

This example demonstrates a deployment with a single Azure VMware Solution private cloud with the following features:

    - A single 3-node management cluster
    - The HCX Addon enabled with the Enterprise license sku
    - An example HCX site key
    - An ExpressRoute authorization key
    - An ExpressRoute Gateway connection to an example ExpressRoute gateway in a virtual network.
    - Diagnostic Settings to send the syslog and metrics to a Log Analytics workspace.
    - A server 2022 jump virtual machine for vcenter and NSX-t console access with:
        - Nat Gateway enabled for outbound internet access
        - Bastion enabled for accessing the Jump Box GUI

```hcl

locals {
  vm_sku = "Standard_D2_v4"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "=0.4.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "=0.4.0"
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

resource "azurerm_public_ip" "nat_gateway" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.nat_gateway.name_unique}-pip"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
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
    ElasticSanSubnet = {
      address_prefixes = ["10.100.3.0/24"]
    }
  }
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
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.express_route_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "ErGw1AZ"
  type                = "ExpressRoute"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.gatewaypip.id
    subnet_id                     = module.gateway_vnet.subnets["GatewaySubnet"].id
    name                          = "default"
    private_ip_address_allocation = "Dynamic"
  }
}

module "avm_res_keyvault_vault" {
  source                 = "Azure/avm-res-keyvault-vault/azurerm"
  version                = "0.5.3"
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

module "elastic_san" {
  source = "../../modules/create_elastic_san_volume"
  #source                = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/create_elastic_san_volume"

  elastic_san_name = "esan-${module.naming.storage_share.name_unique}"
  #resource_group_name   = azurerm_resource_group.this.name
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
          esan_subnet_resource_id              = module.gateway_vnet.subnets["ElasticSanSubnet"].id
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
  resource_group_resource_id     = azurerm_resource_group.this.id
  location                       = azurerm_resource_group.this.location
  name                           = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  sku_name                       = jsondecode(local_file.region_sku_cache.content).sku
  avs_network_cidr               = "10.0.0.0/22"
  internet_enabled               = false
  management_cluster_size        = 3
  extended_network_blocks        = ["10.10.0.0/23"]
  external_storage_address_block = "10.20.0.0/24"

  addons = {
    HCX = {
      hcx_key_names    = ["example_key_1", "example_key_2"]
      hcx_license_type = "Enterprise"
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

  elastic_san_datastores = {
    esan_datastore_cluster1 = {
      esan_volume_resource_id = module.elastic_san.volumes["vg_1-volume_1"].id
      cluster_names           = ["Cluster-1"]
    }
  }

  expressroute_connections = {
    default = {
      name                             = "default_vnet_gateway_connection"
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
  #source = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/create_jump_vm"

  resource_group_name        = azurerm_resource_group.this.name
  resource_group_location    = azurerm_resource_group.this.location
  vm_name                    = "jump-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id      = module.avm_res_keyvault_vault.resource.id
  create_bastion             = true
  bastion_name               = module.naming.bastion_host.name_unique
  bastion_pip_name           = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id = module.gateway_vnet.subnets["AzureBastionSubnet"].id
  vm_subnet_resource_id      = module.gateway_vnet.subnets["VMSubnet"].id
  vm_sku                     = local.vm_sku

  depends_on = [module.avm_res_keyvault_vault, module.gateway_vnet, azurerm_nat_gateway.this_nat_gateway]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~>1.6)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.106)

- <a name="requirement_local"></a> [local](#requirement\_local) (~> 2.5)

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.this_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_nat_gateway.this_nat_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) (resource)
- [azurerm_nat_gateway_public_ip_association.this_nat_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) (resource)
- [azurerm_public_ip.gatewaypip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_public_ip.nat_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_virtual_network_gateway.gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) (resource)
- [local_file.region_sku_cache](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.5.3

### <a name="module_create_jump_vm"></a> [create\_jump\_vm](#module\_create\_jump\_vm)

Source: ../../modules/create_jump_vm

Version:

### <a name="module_elastic_san"></a> [elastic\_san](#module\_elastic\_san)

Source: ../../modules/create_elastic_san_volume

Version:

### <a name="module_gateway_vnet"></a> [gateway\_vnet](#module\_gateway\_vnet)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: =0.1.3

### <a name="module_generate_deployment_region"></a> [generate\_deployment\_region](#module\_generate\_deployment\_region)

Source: ../../modules/generate_deployment_region

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: =0.4.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: =0.4.0

### <a name="module_test_private_cloud"></a> [test\_private\_cloud](#module\_test\_private\_cloud)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->