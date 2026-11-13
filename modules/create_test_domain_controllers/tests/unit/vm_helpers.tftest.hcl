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

mock_provider "template" {
  mock_data "template_file" {
    defaults = {
      rendered = "Write-Output 'Mocked domain-controller configuration'"
    }
  }
}

mock_provider "time" {}

mock_provider "tls" {}

variables {
  dc_subnet_resource_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/dc"
  dc_vm_name                  = "dc-primary"
  dc_vm_name_secondary        = "dc-secondary"
  key_vault_resource_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
  location                    = "eastus2"
  private_ip_address          = "10.100.1.4"
  resource_group_name         = "rg-test"
  virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
}

run "domain_controllers_default_providers" {
  command   = apply
  state_key = "domain_controllers_default"

  providers = {
    azapi    = azapi
    azurerm  = azurerm
    modtm    = modtm
    random   = random
    template = template
    time     = time
    tls      = tls
  }

  assert {
    condition     = endswith(output.resource_id, "/vm-default") && output.primary_dc_private_ip_address == "10.100.1.4"
    error_message = "The domain-controller VM dependency must use the caller's default AzureRM provider."
  }

  assert {
    condition     = output.domain_fqdn == "test.local"
    error_message = "Provider forwarding must preserve the domain-controller configuration."
  }

  assert {
    condition     = module.testvm.resource.location == "eastus2" && module.testvm_secondary.resource.location == "eastus2"
    error_message = "Both domain controllers must use the canonical location when no resource-group location override is supplied."
  }
}

run "domain_controllers_aliased_providers" {
  command   = apply
  state_key = "domain_controllers_aliased"

  variables {
    resource_group_location = "westus3"
  }

  providers = {
    azapi    = azapi.alternate
    azurerm  = azurerm.alternate
    modtm    = modtm
    random   = random
    template = template
    time     = time
    tls      = tls
  }

  assert {
    condition     = endswith(output.resource_id, "/vm-alternate") && output.primary_dc_private_ip_address == "10.100.1.5"
    error_message = "The domain-controller VM dependency must receive the caller's aliased AzureRM provider."
  }

  assert {
    condition     = output.domain_fqdn == "test.local"
    error_message = "Provider forwarding must preserve the domain-controller configuration."
  }

  assert {
    condition     = module.testvm.resource.location == "westus3" && module.testvm_secondary.resource.location == "westus3"
    error_message = "An authored resource-group location must retain precedence for both domain controllers."
  }
}
