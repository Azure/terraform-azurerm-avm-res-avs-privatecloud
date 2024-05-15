variable "elastic_san_name" {
  type        = string
  description = "(Required) Specifies the name of this Elastic SAN resource. Changing this forces a new resource to be created"
}

variable "resource_group_name" {
  type        = string
  description = "(Required) Specifies the name of the Resource Group within which this Elastic SAN resource should exist. Changing this forces a new resource to be created."
}

variable "resource_group_id" {
  type        = string
  description = "(Required) - The Azure Resource ID for the resource group where this Elastic SAN resource will be deployed."
}

variable "location" {
  type        = string
  description = "(Required) The Azure Region where the Elastic SAN resource should exist. Changing this forces a new resource to be created."
}

variable "base_size_in_tib" {
  type        = number
  description = "(Required) - Specifies the base volume size of the ElasticSAN resource in TiB.  Possible values are between `1` and `100`."
}

variable "extended_size_in_tib" {
  type        = number
  description = "(Optional) - Specifies the extended size of the Elastic SAN resource in TB.  Possible values are between `1` and `100`. "

}

variable "tags" {
  type        = map(string)
  description = "(Optional) - a map of tags to apply directly to this resource."
  default     = {}
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
    name            = string
    encryption_type = optional(string, "EncryptionAtRestWithPlatformKey")

    encryption_key_vault_properties = optional(object({
      user_assigned_managed_identity_resource_id = optional(string, null)
      keyName                                    = optional(string, null)
      keyVaultUri                                = optional(string, null)
      keyVersion                                 = optional(string, null)
    }), null)

    managed_identities = optional(object({
      type         = string
      identity_ids = list(string)
    }), null)

    network_rules = optional(map(object({
      id     = string
      action = optional(string, "Allow")
    })), {})

    protocol_type = optional(string, "iSCSI")

    volumes = map(object({
      name                      = string
      size_in_gib               = number
      create_source_resource_id = optional(string, null)
      create_source_source_type = optional(string, "None")
    }))

    private_link_service_connections = map(object({
      private_endpoint_name                = string
      resource_group_name                  = string
      resource_group_location              = string
      esan_subnet_resource_id              = string
      private_link_service_connection_name = string
    }))
  }))
  default = {}

  description = <<DESCRIPTION
This map of objects defines the volume group configurations for this elastic san

- `<map key>` - this arbitrary map key is used to identify each volume group and avoid known before apply issues
  - `name` - (Required) - The name to use for the Elastic SAN volume group
  - `encryption_type` - (Optional) - The type of key used to encrypt data on this volume group.  Possible values are `EncryptionAtRestWithCustomerManagedKey` and `EncryptionAtRestWithPlatformKey`.  Defaults to  `EncryptionAtRestWithPlatformKey`.
  - `encryption_key_vault_properties` - (Optional) Object defining the customer managed key values
    - `user_assigned_managed_identity_resource_id` - (Optional) - The user assigned managed identity to use for accessing the key vault
    - `keyName` - the name of the key to use for customer managed key encryption 
    - `keyVaultUri` - The URI for the key vault where the customer managed key is located.
    - `keyVersion` - The version of the key vault key used for customer managed encryption.
  - `managed_identities` - (Optional) - Object used to describe the managed identities assigned to the volume group
    - `type` - The type of managed identity. Valid values are "systemassigned" or "userassigned"
    - `identity_ids` - A list of user assigned identity id's that are assigned to the volume group
  - `network_rules` - (Optional) a map of objects that describe allow rules for the elasticSAN volume group
    - `<map_key> - The unique key value used for each object
      - `id` - the Azure resource id of the subnet that should be allowed to access this elasticSAN volume group
      - `action` - The action of the virtual network rule.  Currently only `Allow` actions are allowed, and defaults to `Allow`.
  - `protocol_type` - (Optional) - the connection protocol to use for this volume group.  Defaults to `iSCSI`.
  - `volumes` - a map of objects defining the volumes that are part of this volume group
    - `<map_key>` - the unique key value used for each volume object
      - `name` - (Required) - The name to use for the volume
      - `size_in_gib` - The size in gib for the volume 
      - `create_source_resource_id` - (Optional) - The id of the source to create the volume from.  Changing this forces a new resource to be created.
      - `create_source_source_type - (Optiona) - The type of source to create the volume from.  Valid values are `Disk`, `DiskRestorePoint`, `DiskSnapshot`, `VolumeSnapshot`, `None`. Changing this forces a new resource to be created. Defaults to `None`.
  - private_link_service_connections - (Optional) - a map object describing the private link service connections for the volume group
    - `<map_key>` - the unique key value used for each private link service connection
      - `private_endpoint_name` - the name to use for the private endpoint
      - `resource_group_name` - the resource group name where the private endpoint will be deployed
      - `resource_group_location` - the resource group location where the private endpoint will be deployed
      - `esan_subnet_resource_id` - the Azure resource id for the the subnet where the private endpoint will be deployed
      - `private_link_service_connection_name` - The name for the private link service connection  
DESCRIPTION

}

variable "zones" {
  type        = set(string)
  default     = null
  description = "A set of one or more zones where this elastic san resource should be deployed."
}

variable "public_network_access" {
  type        = string
  default     = "Disabled"
  description = "(Optional) - Should the public network access for this resource be enabled.  Defaults to Disabled."
}