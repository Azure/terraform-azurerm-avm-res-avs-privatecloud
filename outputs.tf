output "credentials" {
  description = "This value returns the vcenter and nsxt cloudadmin credential values."
  sensitive   = true
  value       = jsondecode(data.azapi_resource_action.sddc_creds.output)
}

output "hcx_cloud_manager_endpoint_hostname" {
  description = "The hcx cloud manager's hostname"
  value       = split("/", jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.hcxCloudManager)[length(split("/", jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.hcxCloudManager)) - 2]
}

output "hcx_cloud_manager_endpoint_https" {
  description = "The full https endpoint for hcx cloud manager"
  value       = jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.hcxCloudManager
}

output "identity" {
  description = "This output returns the managed identity values if the managed identity has been enabled on the module."
  #value       = var.managed_identities.system_assigned ? azapi_update_resource.managed_identity[0].output : null
  #value = var.managed_identities.system_assigned ? jsondecode(azapi_resource.this_private_cloud.output).identity : null
  #value = var.managed_identities.system_assigned ? azapi_resource.this_private_cloud.output.identity : null
  value = var.managed_identities.system_assigned ? jsondecode(data.azapi_resource.this_private_cloud.output).identity : null
}

output "nsxt_manager_endpoint_hostname" {
  description = "The nsxt endpoint's hostname"
  value       = split("/", jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.nsxtManager)[length(split("/", jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.nsxtManager)) - 2]
}

output "nsxt_manager_endpoint_https" {
  description = "The full https endpoint for nsxt manager."
  value       = jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.nsxtManager
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

output "vcsa_endpoint_hostname" {
  description = "The vcsa endpoint's hostname"
  value       = split("/", jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.vcsa)[length(split("/", jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.vcsa)) - 2]
}

output "vcsa_endpoint_https" {
  description = "The full https endpoint for vcsa."
  value       = jsondecode(data.azapi_resource.this_private_cloud.output).properties.endpoints.vcsa
}
