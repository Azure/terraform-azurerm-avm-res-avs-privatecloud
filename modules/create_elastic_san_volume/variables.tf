variable "elastic_san_name" {
  type = string
  description = "(Required) Specifies the name of this Elastic SAN resource. Changing this forces a new resource to be created"
}

variable "resource_group_name" {
    type = string
    description = "(Required) Specifies the name of the Resource Group within which this Elastic SAN resource should exist. Changing this forces a new resource to be created."  
}

variable "resource_group_id" {
  type = string
  description = "(Required) - The Azure Resource ID for the resource group where this Elastic SAN resource will be deployed."
}

variable "location" {
  type = string
  description = "(Required) The Azure Region where the Elastic SAN resource should exist. Changing this forces a new resource to be created."
}

variable "base_size_in_tib" {
  type = number
  description = "(Required) - Specifies the base volume size of the ElasticSAN resource in TiB.  Possible values are between `1` and `100`."
}

variable "extended_size_in_tib" {
    type = number
    description = "(Optional) - Specifies the extended size of the Elastic SAN resource in TB.  Possible values are between `1` and `100`. "
  
}

variable "tags" {
  type = map(string) 
  description = "(Optional) - a map of tags to apply directly to this resource."
  default = {}
}

variable "sku" {
  type = object({
    name = optional(string, "Premium_ZRS")
    tier = optional(string, "Premium")
  })
  description = <<DESCRIPTION
An object that describes the sku configuration for the Elastic SAN

- `name` - (Required) the sku name.  Possible values are `Premium_LRS` and `Premium_ZRS`.  Changing this forces a new resource to be created.default = {
- `tier - (Optional) - The sku tier.  The only possible value is `Premium`.  Defaults to `Premium`.
}
DESCRIPTION
  default = {
    name = "Premium_ZRS"
    tier = "Premium"
  }
}

variable "elastic_san_volume_groups" {
    type = map(object({
        name = string
        encryption_type = optional(string, "EncryptionAtRestWithPlatformKey")
        #encryption = optional(object({            
        #    key_vault_key_resource_id = optional(string, null)
        #    user_assigned_identity_resource_id = optional(string, null)
        #}), null)

        encryption_key_vault_properties = optional(object({
            user_assigned_managed_identity_resource_id = optional(string, null)
            keyName              = optional(string, null)
            keyVaultUri          = optional(string, null)            
            keyVersion           = optional(string, null)
        }), null)
        
        managed_identities = optional(object({
            type = string
            identity_ids = list(string)
        }), null)

        network_rules = optional(map(object({
            id     = string
            action = optional(string, "Allow")
        })), {})

        protocol_type = optional(string, "iSCSI")

        volumes = map(object({
            name = string
            size_in_gib = number
            create_source_resource_id = optional(string, null)
            create_source_source_type = optional(string, "None")
        }))

        private_link_service_connections = map(object({
            private_endpoint_name = string
            resource_group_name = string
            resource_group_location = string
            esan_subnet_resource_id = string
            private_link_service_connection_name = string
        }))
    }))
    default = {}      
}

variable "zones" {
  type = set(string)
  default = null
}

variable "public_network_access" {
    type = string
    default = "Disabled"
    description = "(Optional) - Should the public network access for this resource be enabled.  Defaults to Disabled."  
}