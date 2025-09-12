#get the CMK vault
data "azurerm_key_vault" "this_vault" {
  count = var.customer_managed_key == null ? 0 : 1

  name                = split("/", var.customer_managed_key.key_vault_resource_id)[8]
  resource_group_name = split("/", var.customer_managed_key.key_vault_resource_id)[4]

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud
  ]
}

#update the private cloud resource to use a CMK
resource "azapi_update_resource" "customer_managed_key" {
  count = var.customer_managed_key == null ? 0 : 1

  resource_id = azapi_resource.this_private_cloud.id
  type        = "Microsoft.AVS/privateClouds@2024-09-01"
  body = {
    properties = {
      encryption = {
        status = "Enabled"
        keyVaultProperties = {
          keyName     = var.customer_managed_key.key_name
          keyVaultUrl = data.azurerm_key_vault.this_vault[0].vault_uri
          keyVersion  = var.customer_managed_key.key_version
        }
      }
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
  ]
}
