#get the CMK vault
data "azurerm_key_vault" "this_vault" {
  count = var.customer_managed_key.key_vault_resource_id != null ? 1 : 0

  name                = split("/", var.customer_managed_key.key_vault_resource_id)[8]
  resource_group_name = split("/", var.customer_managed_key.key_vault_resource_id)[4]
}

#update the private cloud resource to use a CMK
resource "azapi_update_resource" "customer_managed_key" {
  count = var.customer_managed_key.key_vault_resource_id != null ? 1 : 0

  type = "Microsoft.AVS/privateClouds@2022-05-01"
  #name      = "${azapi_resource.this_private_cloud.name}-${var.customer_managed_key.key_name}"
  resource_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
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
  })

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity
  ]
}
