<!-- BEGIN_TF_DOCS -->
# Create Jump VM

This module creates a simple virtual machine that can be used to validate a test configuration by logging into the Vcenter and/or NSX consoles to set up the initial AVS configuration.

```hcl
resource "azurerm_public_ip" "bastion_pip" {
  count = var.create_bastion ? 1 : 0

  allocation_method   = "Static"
  location            = var.resource_group_location
  name                = var.bastion_pip_name
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags
  zones               = ["1", "2", "3"]
}

resource "azurerm_bastion_host" "bastion" {
  count = var.create_bastion ? 1 : 0

  location            = var.resource_group_location
  name                = var.bastion_name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                 = "${var.bastion_name}-ipconf"
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
    subnet_id            = var.bastion_subnet_resource_id
  }
}

#create the virtual machine
module "jumpvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "=0.14.0"

  resource_group_name                    = var.resource_group_name
  location                               = var.resource_group_location
  virtualmachine_os_type                 = "Windows"
  name                                   = var.vm_name
  admin_credential_key_vault_resource_id = var.key_vault_resource_id
  virtualmachine_sku_size                = var.vm_sku
  zone                                   = "1"

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
      name = "${var.vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${var.vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = var.vm_subnet_resource_id
        }
      }
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.105)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.105)

## Resources

The following resources are used by this module:

- [azurerm_bastion_host.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) (resource)
- [azurerm_public_ip.bastion_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_key_vault_resource_id"></a> [key\_vault\_resource\_id](#input\_key\_vault\_resource\_id)

Description: The Azure Resource ID for the key vault where the DSC key and VM passwords will be stored.

Type: `string`

### <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location)

Description: The region for the resource group where the dc will be installed.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group where the dc will be installed.

Type: `string`

### <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name)

Description: The name of the domain controller virtual machine.

Type: `string`

### <a name="input_vm_subnet_resource_id"></a> [vm\_subnet\_resource\_id](#input\_vm\_subnet\_resource\_id)

Description: The subnet resource ID to use for deploying the virtual machine nics.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_bastion_name"></a> [bastion\_name](#input\_bastion\_name)

Description: The name to use for the bastion resource

Type: `string`

Default: `null`

### <a name="input_bastion_pip_name"></a> [bastion\_pip\_name](#input\_bastion\_pip\_name)

Description: The name to use for the bastion public IP resource

Type: `string`

Default: `null`

### <a name="input_bastion_subnet_resource_id"></a> [bastion\_subnet\_resource\_id](#input\_bastion\_subnet\_resource\_id)

Description: The Azure Resource ID for the subnet where the bastion will be connected.

Type: `string`

Default: `null`

### <a name="input_create_bastion"></a> [create\_bastion](#input\_create\_bastion)

Description: Create a bastion resource to use for logging into the domain controller?  Defaults to false.

Type: `bool`

Default: `false`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Map of tags to be assigned to the AVS resources

Type: `map(string)`

Default: `null`

### <a name="input_vm_sku"></a> [vm\_sku](#input\_vm\_sku)

Description: The virtual machine sku size to use for the domain controller.  Defaults to Standard\_D2\_v4

Type: `string`

Default: `"Standard_D2_v4"`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The jump vm resource output required by the spec.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The jump vm resource id output required by the spec.

## Modules

The following Modules are called:

### <a name="module_jumpvm"></a> [jumpvm](#module\_jumpvm)

Source: Azure/avm-res-compute-virtualmachine/azurerm

Version: =0.14.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->