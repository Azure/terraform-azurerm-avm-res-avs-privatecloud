<!-- BEGIN_TF_DOCS -->
# Create Test Domain Controllers

This module creates two windows virtual machines configured as domain controllers for use in testing the identity provider configuration. The VM's include Active Directory Certificate Services and DNS server and are configured to support LDAPs. The module also modifies the DNS configuration in the Vnet to point at the primary DC for DNS.

```hcl

resource "azurerm_public_ip" "bastion_pip" {
  count = var.create_bastion ? 1 : 0

  allocation_method   = "Static"
  location            = var.resource_group_location
  name                = var.bastion_pip_name
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  count = var.create_bastion ? 1 : 0

  location            = var.resource_group_location
  name                = var.bastion_name
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "${var.bastion_name}-ipconf"
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
    subnet_id            = var.bastion_subnet_resource_id
  }
}
#get the deployer user details
data "azurerm_client_config" "current" {}

#Create a self-signed certificate for DSC to use for encrypted deployment
resource "azurerm_key_vault_certificate" "this" {
  key_vault_id = var.key_vault_resource_id
  name         = "${var.dc_vm_name}-dsc-cert"

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      reuse_key  = true
      key_size   = 2048
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = 30
      }
    }
    x509_certificate_properties {
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
      subject            = "CN=${var.dc_vm_name}"
      validity_in_months = 12
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2", "2.5.29.37", "1.3.6.1.4.1.311.80.1"]

      subject_alternative_names {
        dns_names = ["${var.dc_vm_name}.${var.domain_fqdn}"]
      }
    }
  }
}

#Create the template script file
data "template_file" "run_script" {
  template = file("${path.module}/templates/dc_configure_script.ps1")
  vars = {
    thumbprint                   = azurerm_key_vault_certificate.this.thumbprint
    admin_username               = module.testvm.virtual_machine.admin_username
    admin_password               = module.testvm.admin_password
    active_directory_fqdn        = var.domain_fqdn
    active_directory_netbios     = var.domain_netbios_name
    ca_common_name               = "${var.domain_netbios_name} Root CA"
    ca_distinguished_name_suffix = var.domain_distinguished_name
    script_url                   = var.dc_dsc_script_url
    ldap_user                    = var.ldap_user
    ldap_user_password           = random_password.ldap_password.result
    test_admin                   = var.test_admin_user
    test_admin_password          = random_password.test_admin_password.result
    admin_group_name             = var.admin_group_name
    primary_admin_password       = module.testvm.admin_password
  }
}


#build the DC VM
#create the virtual machine
module "testvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "=0.13.0"

  resource_group_name                    = var.resource_group_name
  location                               = var.resource_group_location
  virtualmachine_os_type                 = "Windows"
  name                                   = var.dc_vm_name
  admin_credential_key_vault_resource_id = var.key_vault_resource_id
  virtualmachine_sku_size                = var.dc_vm_sku
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
      name = "${var.dc_vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${var.dc_vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = var.dc_subnet_resource_id
          private_ip_address            = var.private_ip_address
        }
      }
    }
  }

  secrets = [
    {
      key_vault_id = var.key_vault_resource_id
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

  extensions = {
    configure_domain_controller = {
      name                       = "${module.testvm.virtual_machine.name}-configure-domain-controller"
      publisher                  = "Microsoft.Compute"
      type                       = "CustomScriptExtension"
      type_handler_version       = "1.9"
      auto_upgrade_minor_version = true
      protected_settings         = <<PROTECTED_SETTINGS
        {
            "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.run_script.rendered)}')) | Out-File -filepath run_script.ps1\" && powershell -ExecutionPolicy Unrestricted -File run_script.ps1"
        }
      PROTECTED_SETTINGS

    }
  }
}

#adding sleep wait to give the DC time to install the features and configure itself
resource "time_sleep" "wait_600_seconds" {
  create_duration = "600s"

  depends_on = [module.testvm]
}

data "azurerm_virtual_machine" "this_vm" {
  name                = module.testvm.virtual_machine.name
  resource_group_name = var.resource_group_name

  depends_on = [time_sleep.wait_600_seconds, module.testvm]
}

#generate a password for use by the ldap user account
resource "random_password" "ldap_password" {
  length           = 22
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  special          = true
}

resource "random_password" "test_admin_password" {
  length           = 22
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  special          = true
}

#store the ldap user account in the key vault as a secret
resource "azurerm_key_vault_secret" "ldap_password" {
  key_vault_id = var.key_vault_resource_id
  name         = "${var.ldap_user}-password"
  value        = random_password.ldap_password.result
}

#store the testadmin user account in the key vault as a secret
resource "azurerm_key_vault_secret" "test_admin_password" {
  key_vault_id = var.key_vault_resource_id
  name         = "${var.test_admin_user}-password"
  value        = random_password.test_admin_password.result
}

resource "azurerm_virtual_network_dns_servers" "dc_dns" {
  virtual_network_id = var.virtual_network_resource_id
  dns_servers        = [module.testvm.virtual_machine.private_ip_address]

  depends_on = [module.testvm]
}


###############################################################
# Create secondary DC
###############################################################

#Create a self-signed certificate for DSC to use for encrypted deployment
resource "azurerm_key_vault_certificate" "this_secondary" {
  key_vault_id = var.key_vault_resource_id
  name         = "${var.dc_vm_name_secondary}-dsc-cert"

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      reuse_key  = true
      key_size   = 2048
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = 30
      }
    }
    x509_certificate_properties {
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
      subject            = "CN=${var.dc_vm_name_secondary}"
      validity_in_months = 12
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2", "2.5.29.37", "1.3.6.1.4.1.311.80.1"]

      subject_alternative_names {
        dns_names = ["${var.dc_vm_name_secondary}.${var.domain_fqdn}"]
      }
    }
  }
}

#Create the template script file
data "template_file" "run_script_secondary" {
  template = file("${path.module}/templates/dc_configure_script.ps1")
  vars = {
    thumbprint                   = azurerm_key_vault_certificate.this_secondary.thumbprint
    admin_username               = module.testvm_secondary.virtual_machine.admin_username
    admin_password               = module.testvm_secondary.admin_password
    active_directory_fqdn        = var.domain_fqdn
    active_directory_netbios     = var.domain_netbios_name
    ca_common_name               = "${var.domain_netbios_name} Root CA"
    ca_distinguished_name_suffix = var.domain_distinguished_name
    script_url                   = var.dc_dsc_script_url_secondary
    ldap_user                    = var.ldap_user
    ldap_user_password           = random_password.ldap_password.result
    test_admin                   = var.test_admin_user
    test_admin_password          = random_password.test_admin_password.result
    admin_group_name             = var.admin_group_name
    primary_admin_password       = module.testvm.admin_password
  }
}


#build the DC VM
#create the virtual machine
module "testvm_secondary" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "=0.13.0"

  resource_group_name                    = var.resource_group_name
  location                               = var.resource_group_location
  virtualmachine_os_type                 = "Windows"
  name                                   = var.dc_vm_name_secondary
  admin_credential_key_vault_resource_id = var.key_vault_resource_id
  virtualmachine_sku_size                = var.dc_vm_sku
  zone                                   = "2"
  #admin_password                         = module.testvm.admin_password
  #generate_admin_password_or_ssh_key     = false


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
      name = "${var.dc_vm_name_secondary}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${var.dc_vm_name_secondary}-nic1-ipconfig1"
          private_ip_subnet_resource_id = var.dc_subnet_resource_id
        }
      }
    }
  }

  secrets = [
    {
      key_vault_id = var.key_vault_resource_id
      certificate = [
        {
          url   = azurerm_key_vault_certificate.this_secondary.secret_id
          store = "My"
        },
        {
          store = "Root"
          url   = azurerm_key_vault_certificate.this_secondary.secret_id
        }
      ]
    }
  ]

  extensions = {
    configure_domain_controller = {
      name                       = "${module.testvm_secondary.virtual_machine.name}-configure-domain-controller"
      publisher                  = "Microsoft.Compute"
      type                       = "CustomScriptExtension"
      type_handler_version       = "1.9"
      auto_upgrade_minor_version = true
      protected_settings         = <<PROTECTED_SETTINGS
        {
            "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.run_script_secondary.rendered)}')) | Out-File -filepath run_script.ps1\" && powershell -ExecutionPolicy Unrestricted -File run_script.ps1"
        }
      PROTECTED_SETTINGS

    }
  }

  depends_on = [module.testvm, azurerm_virtual_network_dns_servers.dc_dns, time_sleep.wait_600_seconds, data.azurerm_virtual_machine.this_vm]
}

#adding sleep wait to give the DC time to install the features and configure itself
resource "time_sleep" "wait_600_seconds_2" {
  create_duration = "600s"

  depends_on = [module.testvm_secondary]
}

data "azurerm_virtual_machine" "this_vm_secondary" {
  name                = module.testvm_secondary.virtual_machine.name
  resource_group_name = var.resource_group_name

  depends_on = [time_sleep.wait_600_seconds_2, module.testvm_secondary]
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

- <a name="provider_random"></a> [random](#provider\_random)

- <a name="provider_template"></a> [template](#provider\_template)

- <a name="provider_time"></a> [time](#provider\_time)

## Resources

The following resources are used by this module:

- [azurerm_bastion_host.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) (resource)
- [azurerm_key_vault_certificate.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) (resource)
- [azurerm_key_vault_certificate.this_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) (resource)
- [azurerm_key_vault_secret.ldap_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.test_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_public_ip.bastion_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_virtual_network_dns_servers.dc_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_dns_servers) (resource)
- [random_password.ldap_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_password.test_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [time_sleep.wait_600_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [time_sleep.wait_600_seconds_2](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_virtual_machine.this_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_machine) (data source)
- [azurerm_virtual_machine.this_vm_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_machine) (data source)
- [template_file.run_script](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) (data source)
- [template_file.run_script_secondary](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_dc_vm_name"></a> [dc\_vm\_name](#input\_dc\_vm\_name)

Description: The name of the domain controller virtual machine.

Type: `string`

### <a name="input_dc_vm_name_secondary"></a> [dc\_vm\_name\_secondary](#input\_dc\_vm\_name\_secondary)

Description: The name of the domain controller virtual machine.

Type: `string`

### <a name="input_key_vault_resource_id"></a> [key\_vault\_resource\_id](#input\_key\_vault\_resource\_id)

Description: The Azure Resource ID for the key vault where the DSC key and VM passwords will be stored.

Type: `string`

### <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address)

Description: The ip address to use for the primary dc

Type: `string`

### <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location)

Description: The region for the resource group where the dc will be installed.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group where the dc will be installed.

Type: `string`

### <a name="input_virtual_network_resource_id"></a> [virtual\_network\_resource\_id](#input\_virtual\_network\_resource\_id)

Description: The resource ID Of the virtual network where the resources are deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_admin_group_name"></a> [admin\_group\_name](#input\_admin\_group\_name)

Description: the username to use for the account used to query ldap.

Type: `string`

Default: `"vcenterAdmins"`

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

### <a name="input_dc_dsc_script_url"></a> [dc\_dsc\_script\_url](#input\_dc\_dsc\_script\_url)

Description: the github url for the raw DSC configuration script that will be used by the custom script extension.

Type: `string`

Default: `"https://raw.githubusercontent.com/Azure/terraform-azurerm-avm-res-avs-privatecloud/main/modules/create_test_domain_controllers/templates/dc_windows_dsc.ps1"`

### <a name="input_dc_dsc_script_url_secondary"></a> [dc\_dsc\_script\_url\_secondary](#input\_dc\_dsc\_script\_url\_secondary)

Description: the github url for the raw DSC configuration script that will be used by the custom script extension.

Type: `string`

Default: `"https://raw.githubusercontent.com/Azure/terraform-azurerm-avm-res-avs-privatecloud/main/modules/create_test_domain_controllers/templates/dc_secondary_windows_dsc.ps1"`

### <a name="input_dc_subnet_resource_id"></a> [dc\_subnet\_resource\_id](#input\_dc\_subnet\_resource\_id)

Description: domain controller

Type: `string`

Default: `"The Azure Resource ID for the subnet where the DC will be connected."`

### <a name="input_dc_vm_sku"></a> [dc\_vm\_sku](#input\_dc\_vm\_sku)

Description: The virtual machine sku size to use for the domain controller.  Defaults to Standard\_D2\_v4

Type: `string`

Default: `"Standard_D2_v4"`

### <a name="input_domain_distinguished_name"></a> [domain\_distinguished\_name](#input\_domain\_distinguished\_name)

Description: The distinguished name (DN) for the domain to use in ADCS. Defaults to DC=test,DC=local

Type: `string`

Default: `"DC=test,DC=local"`

### <a name="input_domain_fqdn"></a> [domain\_fqdn](#input\_domain\_fqdn)

Description: The fully qualified domain name to use when creating the domain controller. Defaults to test.local

Type: `string`

Default: `"test.local"`

### <a name="input_domain_netbios_name"></a> [domain\_netbios\_name](#input\_domain\_netbios\_name)

Description: The Netbios name for the domain.  Default to test.

Type: `string`

Default: `"test"`

### <a name="input_ldap_user"></a> [ldap\_user](#input\_ldap\_user)

Description: the username to use for the account used to query ldap.

Type: `string`

Default: `"ldapuser"`

### <a name="input_test_admin_user"></a> [test\_admin\_user](#input\_test\_admin\_user)

Description: the username to use for the account used to query ldap.

Type: `string`

Default: `"testAdmin"`

## Outputs

The following outputs are exported:

### <a name="output_dc_details"></a> [dc\_details](#output\_dc\_details)

Description: n/a

### <a name="output_dc_details_secondary"></a> [dc\_details\_secondary](#output\_dc\_details\_secondary)

Description: n/a

### <a name="output_domain_distinguished_name"></a> [domain\_distinguished\_name](#output\_domain\_distinguished\_name)

Description: n/a

### <a name="output_domain_fqdn"></a> [domain\_fqdn](#output\_domain\_fqdn)

Description: n/a

### <a name="output_domain_netbios_name"></a> [domain\_netbios\_name](#output\_domain\_netbios\_name)

Description: n/a

### <a name="output_ldap_user"></a> [ldap\_user](#output\_ldap\_user)

Description: n/a

### <a name="output_ldap_user_password"></a> [ldap\_user\_password](#output\_ldap\_user\_password)

Description: n/a

### <a name="output_primary_dc_private_ip_address"></a> [primary\_dc\_private\_ip\_address](#output\_primary\_dc\_private\_ip\_address)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_testvm"></a> [testvm](#module\_testvm)

Source: Azure/avm-res-compute-virtualmachine/azurerm

Version: =0.13.0

### <a name="module_testvm_secondary"></a> [testvm\_secondary](#module\_testvm\_secondary)

Source: Azure/avm-res-compute-virtualmachine/azurerm

Version: =0.13.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->