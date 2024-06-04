variable "anf_account_name" {
  type        = string
  description = "ANF NetApp Account Name"
}

variable "anf_nfs_allowed_clients" {
  type        = list(string)
  description = "A list of CIDR ranges that should be allowed to attach to this Netapp volume"
}

variable "anf_pool_name" {
  type        = string
  description = "ANF Pool Name"
}

variable "anf_pool_size" {
  type        = number
  description = "Pool Size in TiB"
}

variable "anf_subnet_resource_id" {
  type        = string
  description = "The Azure resource ID Of the subnet enabled for Netapp Files."
}

variable "anf_volume_name" {
  type        = string
  description = "Volume 1 Name"
}

variable "anf_volume_size" {
  type        = number
  description = "Volume 1 Size in GiB"
}

variable "anf_zone_number" {
  type        = number
  description = "The zone where the ANF volume should be deployed."
}

variable "resource_group_location" {
  type        = string
  description = "The region for the resource group where the dc will be installed."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the dc will be installed."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to be assigned to this resource"
}
