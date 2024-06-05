variable "key_vault_resource_id" {
  type        = string
  description = "The Azure Resource ID for the key vault where the DSC key and VM passwords will be stored."
}

variable "resource_group_location" {
  type        = string
  description = "The region for the resource group where the dc will be installed."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the dc will be installed."
}

#names
#vm name
variable "vm_name" {
  type        = string
  description = "The name of the domain controller virtual machine."
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

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Map of tags to be assigned to the AVS resources"
}

#DC sku
variable "vm_sku" {
  type        = string
  default     = "Standard_D2_v4"
  description = "The virtual machine sku size to use for the domain controller.  Defaults to Standard_D2_v4"
}

#domain controller
variable "vm_subnet_resource_id" {
  type    = string
  default = "The Azure Resource ID for the subnet where the DC will be connected."
}
