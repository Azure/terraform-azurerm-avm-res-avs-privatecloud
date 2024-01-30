resource "azurerm_netapp_account" "anf_account" {
  name                = var.anf_account_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_netapp_pool" "anf_pool" {
  name                = var.anf_pool_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf_account.name
  service_level       = "Standard"
  size_in_tb          = var.anf_pool_size
}

resource "azurerm_netapp_volume" "anf_volume" {
  name                            = var.anf_volume_name
  location                        = var.resource_group_location
  resource_group_name             = var.resource_group_name
  account_name                    = azurerm_netapp_account.anf_account.name
  pool_name                       = azurerm_netapp_pool.anf_pool.name
  volume_path                     = var.anf_volume_name
  service_level                   = "Standard"
  subnet_id                       = var.anf_subnet_resource_id
  protocols                       = ["NFSv3"]
  security_style                  = "unix"
  storage_quota_in_gb             = var.anf_volume_size
  snapshot_directory_visible      = true
  zone                            = var.anf_zone_number
  azure_vmware_data_store_enabled = true

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = var.anf_nfs_allowed_clients
    protocols_enabled   = ["NFSv3"]
    root_access_enabled = true
    unix_read_only      = false
    unix_read_write     = true
  }

  lifecycle {
    ignore_changes = [zone]
  }
}

