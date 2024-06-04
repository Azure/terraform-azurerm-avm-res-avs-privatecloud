<!-- BEGIN_TF_DOCS -->
# Create Test Netapp Volume

This module configures an Azure Netapp Files (ANF) account, pool and volume configured for use by AVS testing.

```hcl
resource "azurerm_netapp_account" "anf_account" {
  location            = var.resource_group_location
  name                = var.anf_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_netapp_pool" "anf_pool" {
  account_name        = azurerm_netapp_account.anf_account.name
  location            = var.resource_group_location
  name                = var.anf_pool_name
  resource_group_name = var.resource_group_name
  service_level       = "Standard"
  size_in_tb          = var.anf_pool_size
}

resource "azurerm_netapp_volume" "anf_volume" {
  account_name                    = azurerm_netapp_account.anf_account.name
  location                        = var.resource_group_location
  name                            = var.anf_volume_name
  pool_name                       = azurerm_netapp_pool.anf_pool.name
  resource_group_name             = var.resource_group_name
  service_level                   = "Standard"
  storage_quota_in_gb             = var.anf_volume_size
  subnet_id                       = var.anf_subnet_resource_id
  volume_path                     = var.anf_volume_name
  azure_vmware_data_store_enabled = true
  protocols                       = ["NFSv3"]
  security_style                  = "unix"
  snapshot_directory_visible      = true
  zone                            = var.anf_zone_number

  export_policy_rule {
    allowed_clients     = var.anf_nfs_allowed_clients
    rule_index          = 1
    protocols_enabled   = ["NFSv3"]
    root_access_enabled = true
    unix_read_only      = false
    unix_read_write     = true
  }

  lifecycle {
    ignore_changes = [zone]
  }
}

```

<!-- markdownlint-disable MD033 -->
## Requirements

No requirements.

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm)

## Resources

The following resources are used by this module:

- [azurerm_netapp_account.anf_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/netapp_account) (resource)
- [azurerm_netapp_pool.anf_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/netapp_pool) (resource)
- [azurerm_netapp_volume.anf_volume](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/netapp_volume) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_anf_account_name"></a> [anf\_account\_name](#input\_anf\_account\_name)

Description: ANF NetApp Account Name

Type: `string`

### <a name="input_anf_nfs_allowed_clients"></a> [anf\_nfs\_allowed\_clients](#input\_anf\_nfs\_allowed\_clients)

Description: A list of CIDR ranges that should be allowed to attach to this Netapp volume

Type: `list(string)`

### <a name="input_anf_pool_name"></a> [anf\_pool\_name](#input\_anf\_pool\_name)

Description: ANF Pool Name

Type: `string`

### <a name="input_anf_pool_size"></a> [anf\_pool\_size](#input\_anf\_pool\_size)

Description: Pool Size in TiB

Type: `number`

### <a name="input_anf_subnet_resource_id"></a> [anf\_subnet\_resource\_id](#input\_anf\_subnet\_resource\_id)

Description: The Azure resource ID Of the subnet enabled for Netapp Files.

Type: `string`

### <a name="input_anf_volume_name"></a> [anf\_volume\_name](#input\_anf\_volume\_name)

Description: Volume 1 Name

Type: `string`

### <a name="input_anf_volume_size"></a> [anf\_volume\_size](#input\_anf\_volume\_size)

Description: Volume 1 Size in GiB

Type: `number`

### <a name="input_anf_zone_number"></a> [anf\_zone\_number](#input\_anf\_zone\_number)

Description: The zone where the ANF volume should be deployed.

Type: `number`

### <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location)

Description: The region for the resource group where the dc will be installed.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group where the dc will be installed.

Type: `string`

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_volume_id"></a> [volume\_id](#output\_volume\_id)

Description: n/a

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->