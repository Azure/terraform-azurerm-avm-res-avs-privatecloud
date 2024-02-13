output "credentials" {
  value       = jsondecode(data.azapi_resource_action.sddc_creds.output)
  sensitive   = true
  description = "This value returns the vcenter and nsxt cloudadmin credential values."
}

output "identity" {
  value       = var.managed_identities.system_assigned ? jsondecode(azapi_update_resource.managed_identity[0].output) : null
  description = "This output returns the managed identity values if the managed identity has been enabled on the module."
}

output "resource" {
  value       = jsondecode(azapi_resource.this_private_cloud.output)
  description = "This output returns the full private cloud resource object properties."
}

output "resource_id" {
  value       = azapi_resource.this_private_cloud.id
  description = "The azure resource if of the private cloud."
}

output "system_assigned_mi_principal_id" {
  value       = var.managed_identities.system_assigned == true ? jsondecode(azapi_update_resource.managed_identity[0].output).identity.principalId : null
  description = "The principal id of the system managed identity assigned to the virtual machine"
}