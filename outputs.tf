output "credentials" {
  description = "This value returns the vcenter and nsxt cloudadmin credential values."
  sensitive   = true
  value       = jsondecode(data.azapi_resource_action.sddc_creds.output)
}

output "identity" {
  description = "This output returns the managed identity values if the managed identity has been enabled on the module."
  #value       = var.managed_identities.system_assigned ? azapi_update_resource.managed_identity[0].output : null
  #value = var.managed_identities.system_assigned ? jsondecode(azapi_resource.this_private_cloud.output).identity : null
  #value = var.managed_identities.system_assigned ? azapi_resource.this_private_cloud.output.identity : null
  value = var.managed_identities.system_assigned ? jsondecode(data.azapi_resource.this_private_cloud.output).identity : null
}

output "public_ip" {
  description = "The public IP prefixes when a public ip config is configured for the private cloud."
  value       = length(var.internet_inbound_public_ips) > 0 ? { for key, value in var.internet_inbound_public_ips : key => azapi_resource.public_ip[key].output.properties.publicIPBlock } : null
}

output "resource" {
  description = "This output returns the full private cloud resource object properties."
  #value       = jsondecode(azapi_resource.this_private_cloud.output)
  value = azapi_resource.this_private_cloud.output
}

output "resource_id" {
  description = "The azure resource if of the private cloud."
  #value       = jsondecode(azapi_resource.this_private_cloud.output).id
  value = azapi_resource.this_private_cloud.id
}

output "system_assigned_mi_principal_id" {
  description = "The principal id of the system managed identity assigned to the virtual machine"
  #value       = var.managed_identities.system_assigned == true ? azapi_update_resource.managed_identity[0].output.identity.principalId : null
  #value = var.managed_identities.system_assigned ? jsondecode(azapi_resource.this_private_cloud.output).identity.principalId : null
  #value = var.managed_identities.system_assigned ? azapi_resource.this_private_cloud.output.identity.principalId : null
  value = var.managed_identities.system_assigned ? jsondecode(data.azapi_resource.this_private_cloud.output).identity.principalId : null
}
