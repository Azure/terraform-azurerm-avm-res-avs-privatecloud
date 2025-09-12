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
  version = "=0.19.3"

  location = var.resource_group_location
  name     = var.vm_name
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
  resource_group_name = var.resource_group_name
  zone                = "1"
  account_credentials = {
    key_vault_configuration = {
      resource_id = var.key_vault_resource_id
    }
  }
  managed_identities = {
    system_assigned = true
  }
  os_type  = "Windows"
  sku_size = var.vm_sku
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}
