#generate a random password to use for the initial NSXT admin account password
resource "random_password" "nsxt" {
  length           = 20
  special          = true
  numeric          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  min_lower        = 1
}

#generate a random password to use for the initial vcenter cloudadmin account password
resource "random_password" "vcenter" {
  length           = 20
  special          = true
  numeric          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  min_lower        = 1
}

#assign permissions to the virtual machine if enabled and role assignments included
resource "azurerm_role_assignment" "this_private_cloud" {
  for_each = var.role_assignments

  scope                                  = azapi_resource.this_private_cloud.id
  principal_id                           = each.value.principal_id
  role_definition_id                     = (length(split("/", each.value.role_definition_id_or_name))) > 3 ? each.value.role_definition_id_or_name : null
  role_definition_name                   = (length(split("/", each.value.role_definition_id_or_name))) > 3 ? null : each.value.role_definition_id_or_name
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters
  ]
}

#toggle the system managed identity
resource "azapi_update_resource" "managed_identity" {
  count = var.managed_identities.system_assigned ? 1 : 0

  type        = "Microsoft.AVS/privateClouds@2022-05-01"
  resource_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    identity = {
      type = "systemassigned"
    }
  })
  response_export_values = ["*"]

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags
  ]
}

/* TODO: add this back if we can get a working API call to modify the credentials
#Update the vcenter or nsxt passwords using Terraform instead of deferring to the portal
#This allows for password rotation using Terraform Idempotency
resource "azapi_update_resource" "manual_passwords" {
  count = var.nsxt_password != null || var.vcenter_password != null ? 1 : 0 #if either password value is set, then update the password.  

  type      = "Microsoft.AVS/privateClouds@2022-05-01"
  #name      = "${azapi_resource.this_private_cloud.name}-passwords"
  resource_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      nsxtPassword    = local.nsxt_password
      vcenterPassword = local.vcenter_password
    }
  })      
}
*/

#get SDDC credentials for use with the credentials output
data "azapi_resource_action" "sddc_creds" {
  type                   = "Microsoft.AVS/privateClouds@2022-05-01"
  resource_id            = azapi_resource.this_private_cloud.id
  action                 = "listAdminCredentials"
  response_export_values = ["*"]
}
