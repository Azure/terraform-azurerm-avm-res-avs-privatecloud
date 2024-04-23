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

data "azurerm_client_config" "current" {}

#create the virtual machine
module "jumpvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "=0.11.0"

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
