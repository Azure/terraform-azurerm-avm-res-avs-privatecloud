<!-- BEGIN_TF_DOCS -->
# Interfaces Example

This example demonstrates the core module interfaces.  These include the ability to set tags and locks, enable the system-managed identity, encrypt the VSAN datastore using a customer managed key, configure diagnostic settings, and add resource level role assignments.

It deploys a private cloud with a minimum management cluster, and demonstrates activating the internet SNAT option.

```hcl
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

#get the deployment user details
data "azurerm_client_config" "current" {}

#create a log analytics workspace as a diag settings destination.
resource "azurerm_log_analytics_workspace" "this_workspace" {
  name                = module.naming.log_analytics_workspace.name_unique
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#create a keyvault for storing the example customer managed key 
module "avm-res-keyvault-vault" {
  source                      = "Azure/avm-res-keyvault-vault/azurerm"
  version                     = ">=0.4.0"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  name                        = module.naming.key_vault.name_unique
  resource_group_name         = azurerm_resource_group.this[0].name
  location                    = azurerm_resource_group.this[0].location
  enabled_for_disk_encryption = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    deployment_user_keys = { #give the deployment user access to keys
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    user_managed_identity_keys = { #give the private cloud managed identity access to the key vault
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = module.test_private_cloud[0].private_cloud.properties.identity.principalId
    }
  }
}

#separate the key generation outside the keyvault to try and avoid a circular reference error when permissioning the private cloud managed identity
resource "azurerm_key_vault_key" "generated" {
  name         = "dummy-cmk"
  key_vault_id = module.avm-res-keyvault-vault.resource.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}


# This is the module call
module "test_private_cloud" {
  source = "../../"
  # source             = "Azure/avm-res-avs-privatecloud/azurerm"

  count = length(local.with_quota) > 0 ? 1 : 0 #fails if we don't have quota

  enable_telemetry        = var.enable_telemetry
  resource_group_name     = azurerm_resource_group.this[0].name
  location                = azurerm_resource_group.this[0].location
  name                    = "avs-sddc-${random_string.namestring.result}"
  sku_name                = "av36"
  avs_network_cidr        = "10.96.0.0/22"
  internet_enabled        = true
  management_cluster_size = 3
  hcx_enabled             = true
  hcx_key_names           = ["test_site_key_1"]
  expressroute_auth_keys  = ["test_auth_key_1"]

  #demonstrate the role_assignments interface
  role_assignments = {
    deployment_user_secrets = { #give the deployment user access private cloud directly
      role_definition_id_or_name = "Contributor"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  #demonstrate the tags interface
  tags = {
    scenario = "avs_sddc_interfaces"
  }

  #demonstrate the diagnostic settings interface
  diagnostic_settings = {
    avs_diags = {
      name                  = module.naming.monitor_diagnostic_setting.name_unique
      workspace_resource_id = azurerm_log_analytics_workspace.this_workspace.id
      metric_categories     = ["AllMetrics"]
      log_groups            = ["allLogs"]
    }
  }

  #demonstrate the managed Identity interface
  managed_identities = {
    system_assigned = true
  }

  #demonstrate customer managed keys
  customer_managed_key = {
    key_vault_resource_id = module.avm-res-keyvault-vault.resource.id
    key_name              = azurerm_key_vault_key.generated.name
    key_version           = azurerm_key_vault_key.generated.version
  }

  #demonstrate the locks interface
  lock = {
    name = "lock-avs-sddc-${random_string.namestring.result}"
    type = "CanNotDelete"
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.6.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>=1.9.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (>=1.9.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault_key.generated](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) (resource)
- [azurerm_log_analytics_workspace.this_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.namestring](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azapi_resource_action.quota](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

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

### <a name="module_avm-res-keyvault-vault"></a> [avm-res-keyvault-vault](#module\_avm-res-keyvault-vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: >=0.4.0

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.4.0

### <a name="module_test_private_cloud"></a> [test\_private\_cloud](#module\_test\_private\_cloud)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->