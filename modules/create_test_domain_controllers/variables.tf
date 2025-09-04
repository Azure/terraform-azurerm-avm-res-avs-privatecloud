#domain controller
variable "dc_subnet_resource_id" {
  type        = string
  description = "The Azure Resource ID for the subnet where the DC will be connected."
}

#names
#vm name
variable "dc_vm_name" {
  type        = string
  description = "The name of the domain controller virtual machine."
}

variable "dc_vm_name_secondary" {
  type        = string
  description = "The name of the domain controller virtual machine."
}

variable "key_vault_resource_id" {
  type        = string
  description = "The Azure Resource ID for the key vault where the DSC key and VM passwords will be stored."
}

variable "private_ip_address" {
  type        = string
  description = "The ip address to use for the primary dc"
}

variable "resource_group_location" {
  type        = string
  description = "The region for the resource group where the dc will be installed."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the dc will be installed."
}

variable "virtual_network_resource_id" {
  type        = string
  description = "The resource ID Of the virtual network where the resources are deployed."
}

variable "admin_group_name" {
  type        = string
  default     = "vcenterAdmins"
  description = "the username to use for the account used to query ldap."
}

#bastion name
variable "bastion_name" {
  type        = string
  default     = null
  description = "The name to use for the bastion resource"
}

#bastion pip name
variable "bastion_pip_name" {
  type        = string
  default     = null
  description = "The name to use for the bastion public IP resource"
}

#subnet definitions
#bastion
variable "bastion_subnet_resource_id" {
  type        = string
  default     = null
  description = "The Azure Resource ID for the subnet where the bastion will be connected."
}

#create bastion
variable "create_bastion" {
  type        = bool
  default     = false
  description = "Create a bastion resource to use for logging into the domain controller?  Defaults to false."
}

variable "dc_dsc_script_url" {
  type        = string
  default     = "https://raw.githubusercontent.com/Azure/terraform-azurerm-avm-res-avs-privatecloud/main/modules/create_test_domain_controllers/templates/dc_windows_dsc.ps1"
  description = "the github url for the raw DSC configuration script that will be used by the custom script extension."
}

variable "dc_dsc_script_url_secondary" {
  type        = string
  default     = "https://raw.githubusercontent.com/Azure/terraform-azurerm-avm-res-avs-privatecloud/main/modules/create_test_domain_controllers/templates/dc_secondary_windows_dsc.ps1"
  description = "the github url for the raw DSC configuration script that will be used by the custom script extension."
}

#DC sku
variable "dc_vm_sku" {
  type        = string
  default     = "Standard_D2_v4"
  description = "The virtual machine sku size to use for the domain controller.  Defaults to Standard_D2_v4"
}

variable "domain_distinguished_name" {
  type        = string
  default     = "DC=test,DC=local"
  description = "The distinguished name (DN) for the domain to use in ADCS. Defaults to DC=test,DC=local"
}

#domain fqdn
variable "domain_fqdn" {
  type        = string
  default     = "test.local"
  description = "The fully qualified domain name to use when creating the domain controller. Defaults to test.local"
}

#domain netbios
variable "domain_netbios_name" {
  type        = string
  default     = "test"
  description = "The Netbios name for the domain.  Default to test."
}

variable "ldap_user" {
  type        = string
  default     = "ldapuser"
  description = "the username to use for the account used to query ldap."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Map of tags to be assigned to the AVS resources"
}

variable "test_admin_user" {
  type        = string
  default     = "testAdmin"
  description = "the username to use for the account used to query ldap."
}
