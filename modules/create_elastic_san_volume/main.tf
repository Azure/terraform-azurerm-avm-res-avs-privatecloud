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
  location               = var.location
  name                   = var.elastic_san_name
  parent_id              = var.resource_group_id
  response_export_values = ["*"]
  tags                   = var.tags
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
