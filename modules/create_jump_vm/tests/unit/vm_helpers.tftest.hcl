mock_provider "azapi" {}

mock_provider "azapi" {
  alias = "alternate"
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azurerm_windows_virtual_machine" {
    defaults = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-default"
      private_ip_address   = "10.100.1.4"
      private_ip_addresses = ["10.100.1.4"]
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkInterfaces/nic-default"
    }
  }

  mock_resource "azurerm_key_vault_certificate" {
    defaults = {
      secret_id  = "https://kv-test.vault.azure.net/secrets/dc-certificate/00000000000000000000000000000000"
      thumbprint = "0000000000000000000000000000000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "alternate"

  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azurerm_windows_virtual_machine" {
    defaults = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-alternate"
      private_ip_address   = "10.100.1.5"
      private_ip_addresses = ["10.100.1.5"]
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkInterfaces/nic-alternate"
    }
  }

  mock_resource "azurerm_key_vault_certificate" {
    defaults = {
      secret_id  = "https://kv-test.vault.azure.net/secrets/dc-certificate/00000000000000000000000000000000"
      thumbprint = "0000000000000000000000000000000000000000"
    }
  }
}

mock_provider "modtm" {
  mock_data "modtm_module_source" {
    defaults = {
      module_source  = "registry.terraform.io/Azure/avm-res-compute-virtualmachine/azurerm"
      module_version = "0.19.3"
    }
  }
}

mock_provider "random" {
  mock_resource "random_password" {
    defaults = {
      result = "MockPassword1234567890!AB"
    }
  }
}

mock_provider "tls" {}

variables {
  key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
  location              = "eastus2"
  resource_group_name   = "rg-test"
  vm_name               = "vm-test"
  vm_subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/vm"
}

run "jump_vm_default_providers" {
  command   = apply
  state_key = "jump_vm_default"

  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
    tls     = tls
  }

  assert {
    condition     = endswith(output.resource_id, "/vm-default")
    error_message = "The jump VM must use the caller's default AzureRM provider."
  }

  assert {
    condition     = output.resource.location == "eastus2"
    error_message = "The jump VM must use the canonical location when no resource-group location override is supplied."
  }
}

run "jump_vm_aliased_providers" {
  command   = apply
  state_key = "jump_vm_aliased"

  variables {
    resource_group_location = "westus3"
  }

  providers = {
    azapi   = azapi.alternate
    azurerm = azurerm.alternate
    modtm   = modtm
    random  = random
    tls     = tls
  }

  assert {
    condition     = endswith(output.resource_id, "/vm-alternate")
    error_message = "The jump VM dependency must receive the caller's aliased AzureRM provider."
  }

  assert {
    condition     = output.resource.location == "westus3"
    error_message = "An authored resource-group location must retain precedence for the jump VM."
  }
}
