module "this" {
  source = "../../../../modules/create_jump_vm"

  providers = {
    azapi   = azapi
    azurerm = azurerm
  }

  key_vault_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
  resource_group_location = var.location
  resource_group_name     = "rg-test"
  vm_name                 = "vm-test"
  vm_subnet_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/vm"
}
