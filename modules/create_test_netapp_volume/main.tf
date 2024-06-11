resource "azurerm_netapp_account" "anf_account" {
  location            = var.resource_group_location
  name                = var.anf_account_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_netapp_pool" "anf_pool" {
  account_name        = azurerm_netapp_account.anf_account.name
  location            = var.resource_group_location
  name                = var.anf_pool_name
  resource_group_name = var.resource_group_name
  service_level       = "Standard"
  size_in_tb          = var.anf_pool_size
  tags                = var.tags
}

resource "azurerm_netapp_volume" "anf_volume" {
  account_name                    = azurerm_netapp_account.anf_account.name
  location                        = var.resource_group_location
  name                            = var.anf_volume_name
  pool_name                       = azurerm_netapp_pool.anf_pool.name
  resource_group_name             = var.resource_group_name
  service_level                   = "Standard"
  storage_quota_in_gb             = var.anf_volume_size
  subnet_id                       = var.anf_subnet_resource_id
  volume_path                     = var.anf_volume_name
  azure_vmware_data_store_enabled = true
  protocols                       = ["NFSv3"]
  security_style                  = "unix"
  snapshot_directory_visible      = true
  tags                            = var.tags
  zone                            = var.anf_zone_number

  export_policy_rule {
    allowed_clients     = var.anf_nfs_allowed_clients
    rule_index          = 1
    protocols_enabled   = ["NFSv3"]
    root_access_enabled = true
    unix_read_only      = false
    unix_read_write     = true
  }

  lifecycle {
    ignore_changes = [zone]
  }
}

