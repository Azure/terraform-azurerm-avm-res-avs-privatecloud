
resource "azurerm_public_ip" "bastion_pip" {
  count = var.create_bastion ? 1 : 0

  name                = var.bastion_pip_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  count               = var.create_bastion ? 1 : 0
  name                = var.bastion_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "${var.bastion_name}-ipconf"
    subnet_id            = var.bastion_subnet_resource_id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }
}
#get the deployer user details
data "azurerm_client_config" "current" {}

#Create a self-signed certificate for DSC to use for encrypted deployment
resource "azurerm_key_vault_certificate" "this" {
  name         = "${var.dc_vm_name}-dsc-cert"
  key_vault_id = var.key_vault_resource_id

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
        dns_names = ["${var.dc_vm_name}.${var.domain_fqdn}"]
      }

      subject            = "CN=${var.dc_vm_name}"
      validity_in_months = 12
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
  version = "=0.11.0"

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
  depends_on = [module.testvm]

  create_duration = "600s"
}

data "azurerm_virtual_machine" "this_vm" {
  name                = module.testvm.virtual_machine.name
  resource_group_name = var.resource_group_name
  depends_on          = [time_sleep.wait_600_seconds, module.testvm]
}

#generate a password for use by the ldap user account
resource "random_password" "ldap_password" {
  length           = 22
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  special          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
}

resource "random_password" "test_admin_password" {
  length           = 22
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  special          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
}

#store the ldap user account in the key vault as a secret
resource "azurerm_key_vault_secret" "ldap_password" {
  name         = "${var.ldap_user}-password"
  value        = random_password.ldap_password.result
  key_vault_id = var.key_vault_resource_id
}

#store the testadmin user account in the key vault as a secret
resource "azurerm_key_vault_secret" "test_admin_password" {
  name         = "${var.test_admin_user}-password"
  value        = random_password.test_admin_password.result
  key_vault_id = var.key_vault_resource_id
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
  name         = "${var.dc_vm_name_secondary}-dsc-cert"
  key_vault_id = var.key_vault_resource_id

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
        dns_names = ["${var.dc_vm_name_secondary}.${var.domain_fqdn}"]
      }

      subject            = "CN=${var.dc_vm_name_secondary}"
      validity_in_months = 12
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
  version = "=0.11.0"

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
  depends_on = [module.testvm_secondary]

  create_duration = "600s"
}

data "azurerm_virtual_machine" "this_vm_secondary" {
  name                = module.testvm_secondary.virtual_machine.name
  resource_group_name = var.resource_group_name
  depends_on          = [time_sleep.wait_600_seconds_2, module.testvm_secondary]
}
