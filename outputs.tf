output "credentials" {
  description = "This value returns the vcenter and nsxt cloudadmin credential values."
  sensitive   = true
  value       = jsondecode(data.azapi_resource_action.sddc_creds.output)
}

output "identity" {
  description = "This output returns the managed identity values if the managed identity has been enabled on the module."
  #value       = var.managed_identities.system_assigned ? azapi_update_resource.managed_identity[0].output : null
  value = var.managed_identities.system_assigned ? jsondecode(azapi_resource.this_private_cloud.output).identity : null
}

output "resource" {
  description = "This output returns the full private cloud resource object properties."
  value       = jsondecode(azapi_resource.this_private_cloud.output)
}

output "resource_id" {
  description = "The azure resource if of the private cloud."
  value       = jsondecode(azapi_resource.this_private_cloud.output).id
}

output "system_assigned_mi_principal_id" {
  description = "The principal id of the system managed identity assigned to the virtual machine"
  #value       = var.managed_identities.system_assigned == true ? azapi_update_resource.managed_identity[0].output.identity.principalId : null
  value = var.managed_identities.system_assigned ? jsondecode(azapi_resource.this_private_cloud.output).identity.principalId : null
}
