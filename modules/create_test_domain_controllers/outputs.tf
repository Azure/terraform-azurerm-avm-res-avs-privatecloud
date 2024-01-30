output "dc_details" {
  value     = data.azurerm_virtual_machine.this_vm
  sensitive = false
}

output "dc_details_secondary" {
  value = data.azurerm_virtual_machine.this_vm_secondary
}

output "domain_fqdn" {
  value = var.domain_fqdn
}

output "domain_distinguished_name" {
  #value = "cn=users,${var.domain_distinguished_name}"
  value = var.domain_distinguished_name
}

output "domain_netbios_name" {
  value = var.domain_netbios_name
}

output "ldap_user" {
  value = "azureuser@${var.domain_fqdn}"
  #value = "${var.ldap_user}@${var.domain_fqdn}"
}

output "ldap_user_password" {
  value = module.testvm.admin_password
  #value = random_password.ldap_password.result
  sensitive = true
}

output "primary_dc_private_ip_address" {
  value = module.testvm.virtual_machine_azurerm.private_ip_address
}
