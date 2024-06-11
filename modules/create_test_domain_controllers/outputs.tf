output "dc_details" {
  description = "The primary domain controller data resource output."
  value       = data.azurerm_virtual_machine.this_vm
}

output "dc_details_secondary" {
  description = "The secondary domain controller data resource output."
  value       = data.azurerm_virtual_machine.this_vm_secondary
}

output "domain_distinguished_name" {
  description = "The distinguished name for the domain deployed on the domain controllers."
  #value = "cn=users,${var.domain_distinguished_name}"
  value = var.domain_distinguished_name
}

output "domain_fqdn" {
  description = "The fully qualified domain name for the domain deployed on the domain controllers."
  value       = var.domain_fqdn
}

output "domain_netbios_name" {
  description = "The domain short name or netbios name for the domain deployed on the domain controllers."
  value       = var.domain_netbios_name
}

output "ldap_user" {
  description = "The ldap user name created for use in testing the identity configuration functions of the AVM AVS module."
  value       = "azureuser@${var.domain_fqdn}"
}

output "ldap_user_password" {
  description = "The ldap user password value for use in testing the identity configuration functions of the AVM AVS module."
  #value = random_password.ldap_password.result
  sensitive = true
  value     = module.testvm.admin_password
}

output "primary_dc_private_ip_address" {
  description = "The IP address for the primary domain controller."
  value       = module.testvm.virtual_machine_azurerm.private_ip_address
}

output "resource" {
  description = "the full module output for the primary domain controller. Including this to comply with the spec tests."
  value       = module.testvm
}

output "resource_id" {
  description = "The primary domain controller id.  Included to comply with the spec."
  value       = module.testvm.virtual_machine_azurerm.id
}
