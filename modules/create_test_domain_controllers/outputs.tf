output "dc_details" {
  value = data.azurerm_virtual_machine.this_vm
  description = "The primary domain controller data resource output."
}

output "dc_details_secondary" {
  value = data.azurerm_virtual_machine.this_vm_secondary
  description = "The secondary domain controller data resource output."
}

output "domain_distinguished_name" {
  #value = "cn=users,${var.domain_distinguished_name}"
  value = var.domain_distinguished_name
  description = "The distinguished name for the domain deployed on the domain controllers."
}

output "domain_fqdn" {
  value = var.domain_fqdn
  description = "The fully qualified domain name for the domain deployed on the domain controllers."
}

output "domain_netbios_name" {
  value = var.domain_netbios_name
  description = "The domain short name or netbios name for the domain deployed on the domain controllers."
}

output "ldap_user" {
  value = "azureuser@${var.domain_fqdn}"
  description = "The ldap user name created for use in testing the identity configuration functions of the AVM AVS module."
}

output "ldap_user_password" {
  #value = random_password.ldap_password.result
  sensitive = true
  value     = module.testvm.admin_password
  description = "The ldap user password value for use in testing the identity configuration functions of the AVM AVS module."
}

output "primary_dc_private_ip_address" {
  value = module.testvm.virtual_machine_azurerm.private_ip_address
  description = "The IP address for the primary domain controller."
}

output "resource" {
  value = module.testvm
  description = "the full module output for the primary domain controller. Including this to comply with the spec tests."
}

output "resource_id" {
  value = module.testvm.virtual_machine_azurerm.id
  description = "The primary domain controller id.  Included to comply with the spec."
}
