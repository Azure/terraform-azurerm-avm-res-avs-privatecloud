# TODO: insert outputs here.
/*
output "private_cloud" {
  value = jsondecode(azapi_resource.this_private_cloud.output)
}
*/
output "credentials" {
  value     = jsondecode(data.azapi_resource_action.sddc_creds.output)
  sensitive = true
}

output "identity" {
  value = var.managed_identities.system_assigned ? jsondecode(azapi_update_resource.managed_identity[0].output) : null
}

output "id" {
  value = azapi_resource.this_private_cloud.id
}