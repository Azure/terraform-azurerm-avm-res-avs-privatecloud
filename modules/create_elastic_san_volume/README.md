<!-- BEGIN_TF_DOCS -->
# Create Elastic SAN Volume

This module creates a simple Elastic SAN pool and volume that is configured to provide an IScSI block external datastore for AVS.

```hcl
locals {
  vg_private_endpoints = { for pe in flatten([
    for vgk, vgv in var.elastic_san_volume_groups : [
      for pek, pev in vgv.private_link_service_connections : {
        vg_key     = vgk
        pe_key     = pek
        connection = pev
      }
    ]
  ]) : "${pe.vg_key}-${pe.pe_key}" => pe }
  #flatten the volumes in volume groups
  vg_volumes = { for vol in flatten([
    for vgk, vgv in var.elastic_san_volume_groups : [
      for vk, vv in vgv.volumes : {
        vg_key = vgk
        vv_key = vk
        volume = vv
      }
    ]
  ]) : "${vol.vg_key}-${vol.vv_key}" => vol }
}

resource "azapi_resource" "this_elastic_san" {
  type = "Microsoft.ElasticSan/elasticSans@2023-01-01"
  body = {
    properties = {
      availabilityZones       = var.zones
      baseSizeTiB             = var.base_size_in_tib
      extendedCapacitySizeTiB = var.extended_size_in_tib
      publicNetworkAccess     = var.public_network_access
      sku                     = var.sku
    }
  }
  location  = var.location
  name      = var.elastic_san_name
  parent_id = var.resource_group_id
  tags      = var.tags
}

locals {
  encryption_properties = { for key, value in var.elastic_san_volume_groups : key => {
    identity = value.encryption_key_vault_properties.user_assigned_managed_identity_resource_id
    keyVaultProperties = {
      keyName     = value.encryption_key_vault_properties.keyName
      keyVaultUri = value.encryption_key_vault_properties.keyVaultUri
      keyVersion  = value.encryption_key_vault_properties.keyVersion
    }
  } if(value.encryption_key_vault_properties != null) }
}

resource "azapi_resource" "this_elastic_san_volume_group" {
  for_each = var.elastic_san_volume_groups

  type = "Microsoft.ElasticSan/elasticSans/volumegroups@2023-01-01"
  body = jsondecode(each.value.encryption_key_vault_properties != null ? jsonencode({
    properties = {
      encryption           = each.value.encryption_type
      encryptionProperties = local.encryption_properties
      networkAcls = {
        virtualNetworkRules = [for rule in each.value.network_rules : rule if rule.action == "Allow"]
      }
      protocolType = each.value.protocol_type
    }
    }) : jsonencode({
    properties = {
      encryption = each.value.encryption_type
      networkAcls = {
        virtualNetworkRules = [for rule in each.value.network_rules : rule if rule.action == "Allow"]
      }
      protocolType = each.value.protocol_type
    }
  }))
  name                      = each.value.name
  parent_id                 = azapi_resource.this_elastic_san.id
  schema_validation_enabled = false

  dynamic "identity" {
    for_each = each.value.managed_identities != null ? ["identity"] : []
    content {
      type         = each.value.managed_identities.type
      identity_ids = each.value.managed_identities.identity_ids
    }
  }
}

resource "azapi_resource" "this_elastic_san_volume" {
  for_each = local.vg_volumes

  type = "Microsoft.ElasticSan/elasticSans/volumegroups/volumes@2023-01-01"
  body = {
    properties = {
      creationData = {
        createSource = each.value.volume.create_source_source_type
        sourceId     = each.value.volume.create_source_resource_id
      }
      sizeGiB = each.value.volume.size_in_gib
    }
  }
  name                      = each.value.volume.name
  parent_id                 = azapi_resource.this_elastic_san_volume_group[each.value.vg_key].id
  schema_validation_enabled = false

  depends_on = [azurerm_private_endpoint.this]
}

resource "azurerm_private_endpoint" "this" {
  for_each = local.vg_private_endpoints

  location            = each.value.connection.resource_group_location
  name                = each.value.connection.private_endpoint_name
  resource_group_name = each.value.connection.resource_group_name
  subnet_id           = each.value.connection.esan_subnet_resource_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.connection.private_link_service_connection_name
    private_connection_resource_id = azapi_resource.this_elastic_san.id
    subresource_names              = [azapi_resource.this_elastic_san_volume_group[each.value.vg_key].name]
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13, != 1.13.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.105)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.105)

## Resources

The following resources are used by this module:

- [azapi_resource.this_elastic_san](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this_elastic_san_volume](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this_elastic_san_volume_group](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_base_size_in_tib"></a> [base\_size\_in\_tib](#input\_base\_size\_in\_tib)

Description: (Required) - Specifies the base volume size of the ElasticSAN resource in TiB.  Possible values are between `1` and `100`.

Type: `number`

### <a name="input_elastic_san_name"></a> [elastic\_san\_name](#input\_elastic\_san\_name)

Description: (Required) Specifies the name of this Elastic SAN resource. Changing this forces a new resource to be created

Type: `string`

### <a name="input_extended_size_in_tib"></a> [extended\_size\_in\_tib](#input\_extended\_size\_in\_tib)

Description: (Optional) - Specifies the extended size of the Elastic SAN resource in TB.  Possible values are between `1` and `100`.

Type: `number`

### <a name="input_location"></a> [location](#input\_location)

Description: (Required) The Azure Region where the Elastic SAN resource should exist. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id)

Description: (Required) - The Azure Resource ID for the resource group where this Elastic SAN resource will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_elastic_san_volume_groups"></a> [elastic\_san\_volume\_groups](#input\_elastic\_san\_volume\_groups)

Description: This map of objects defines the volume group configurations for this elastic san

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
  - `protocol\_type` - (Optional) - the connection protocol to use for this volume group.  Defaults to `iSCSI`.
  - `volumes` - a map of objects defining the volumes that are part of this volume group
    - `<map\_key>` - the unique key value used for each volume object
      - `name` - (Required) - The name to use for the volume
      - `size\_in\_gib` - The size in gib for the volume
      - `create\_source\_resource\_id` - (Optional) - The id of the source to create the volume from.  Changing this forces a new resource to be created.
      - `create\_source\_source\_type - (Optiona) - The type of source to create the volume from.  Valid values are `Disk`, `DiskRestorePoint`, `DiskSnapshot`, `VolumeSnapshot`, `None`. Changing this forces a new resource to be created. Defaults to `None`.
  - private\_link\_service\_connections - (Optional) - a map object describing the private link service connections for the volume group
    - `<map_key>` - the unique key value used for each private link service connection
      - `private_endpoint_name` - the name to use for the private endpoint
      - `resource_group_name` - the resource group name where the private endpoint will be deployed
      - `resource_group_location` - the resource group location where the private endpoint will be deployed
      - `esan_subnet_resource_id` - the Azure resource id for the the subnet where the private endpoint will be deployed
      - `private_link_service_connection_name` - The name for the private link service connection  

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_public_network_access"></a> [public\_network\_access](#input\_public\_network\_access)

Description: (Optional) - Should the public network access for this resource be enabled.  Defaults to Disabled.

Type: `string`

Default: `"Disabled"`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: An object that describes the sku configuration for the Elastic SAN

- `name` - (Required) the sku name.  Possible values are `Premium_LRS` and `Premium_ZRS`.  Changing this forces a new resource to be created.default = {
- `tier - (Optional) - The sku tier.  The only possible value is `Premium`.  Defaults to `Premium`.
}
`

Type:

```hcl
object({
    name = optional(string, "Premium_ZRS")
    tier = optional(string, "Premium")
  })
```

Default:

```json
{
  "name": "Premium_ZRS",
  "tier": "Premium"
}
```

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Map of tags to be assigned to the AVS resources

Type: `map(string)`

Default: `null`

### <a name="input_zones"></a> [zones](#input\_zones)

Description: A set of one or more zones where this elastic san resource should be deployed.

Type: `set(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_elastic_san"></a> [elastic\_san](#output\_elastic\_san)

Description: The full elastic san resource output.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The full elastic san resource output

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource id of the elastic san volume

### <a name="output_volumes"></a> [volumes](#output\_volumes)

Description: The full elastic san volume output

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->