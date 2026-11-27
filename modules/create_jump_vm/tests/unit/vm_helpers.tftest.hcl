mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-default"
    }
  }
}

mock_provider "azapi" {
  alias = "alternate"

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-alternate"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "azurerm" {
  alias = "alternate"
}

mock_provider "random" {
  mock_resource "random_password" {
    defaults = {
      result = "MockPassword1234567890!AB"
    }
  }
}

mock_provider "tls" {}

mock_provider "time" {}

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
    random  = random
    time    = time
    tls     = tls
  }

  assert {
    condition     = endswith(output.resource_id, "/vm-default")
    error_message = "The jump VM must use the caller's default AzAPI provider."
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
    random  = random
    time    = time
    tls     = tls
  }

  assert {
    condition     = endswith(output.resource_id, "/vm-alternate")
    error_message = "The jump VM dependency must receive the caller's aliased AzAPI provider."
  }

  assert {
    condition     = output.resource.location == "westus3"
    error_message = "An authored resource-group location must retain precedence for the jump VM."
  }
}
