output "dc_details" {
    value = data.azurerm_virtual_machine.this_vm
    sensitive = false
}

output "domain_fqdn" {
    value = var.domain_fqdn
}

output "domain_distinguished_name" {
    value = var.domain_distinguished_name
}

output "domain_netbios_name" {
    value = var.domain_netbios_name
}

output "ldap_user" {
    value = var.ldap_user
}

output "ldap_user_password" {
    value = random_password.ldap_password.result
    sensitive = true
}
