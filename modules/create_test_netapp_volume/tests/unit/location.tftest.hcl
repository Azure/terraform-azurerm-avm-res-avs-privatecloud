mock_provider "azurerm" {}

variables {
  anf_account_name        = "anf-test"
  anf_nfs_allowed_clients = ["10.0.0.0/24"]
  anf_pool_name           = "pool-test"
  anf_pool_size           = 4
  anf_subnet_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/netapp"
  anf_volume_name         = "volume-test"
  anf_volume_size         = 100
  anf_zone_number         = 1
  location                = "eastus2"
  resource_group_name     = "rg-test"
}

run "canonical_location" {
  command = plan

  assert {
    condition     = azurerm_netapp_account.anf_account.location == "eastus2" && azurerm_netapp_pool.anf_pool.location == "eastus2" && azurerm_netapp_volume.anf_volume.location == "eastus2"
    error_message = "The canonical location must place all NetApp resources when no resource-group location override is supplied."
  }
}

run "authored_location_override" {
  command = plan

  variables {
    resource_group_location = "westus3"
  }

  assert {
    condition     = azurerm_netapp_account.anf_account.location == "westus3" && azurerm_netapp_pool.anf_pool.location == "westus3" && azurerm_netapp_volume.anf_volume.location == "westus3"
    error_message = "An authored resource-group location must retain precedence over the canonical fallback."
  }
}
