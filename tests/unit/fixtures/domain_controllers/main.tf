module "this" {
  source = "../../../../modules/create_test_domain_controllers"

  providers = {
    azapi    = azapi
    azurerm  = azurerm
    random   = random
    template = template
    time     = time
  }

  dc_subnet_resource_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/dc"
  dc_vm_name                  = "dc-primary"
  dc_vm_name_secondary        = "dc-secondary"
  key_vault_resource_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
  private_ip_address          = "10.100.1.4"
  resource_group_location     = var.location
  resource_group_name         = "rg-test"
  virtual_network_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
}
