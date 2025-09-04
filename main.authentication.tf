#generate a random password to use for the initial NSXT admin account password
resource "random_password" "nsxt" {
  length           = 20
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  special          = true
}

#generate a random password to use for the initial vcenter cloudadmin account password
resource "random_password" "vcenter" {
  length           = 20
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  special          = true
}

#assign permissions to the virtual machine if enabled and role assignments included
resource "azurerm_role_assignment" "this_private_cloud" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this_private_cloud.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters
  ]
}

/* TODO: add this back if we can get a working API call to modify the credentials
#Update the vcenter or nsxt passwords using Terraform instead of deferring to the portal
#This allows for password rotation using Terraform Idempotency
resource "azapi_update_resource" "manual_passwords" {
  count = var.nsxt_password != null || var.vcenter_password != null ? 1 : 0 #if either password value is set, then update the password.  

  type      = "Microsoft.AVS/privateClouds@2023-03-01"
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
  action                 = "listAdminCredentials"
  resource_id            = azapi_resource.this_private_cloud.id
  type                   = "Microsoft.AVS/privateClouds@2024-09-01"
  response_export_values = ["*"]
}
