locals {
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

  vg_network_rules = { for nr in flatten([
    for vgk, vgv in var.elastic_san_volume_groups : [
      for nrk, nrv in vgv.network_rules : {
        vg_key = vgk
        nr_key = nrk
        rule   = nrv
      }
    ]
  ]) : "${nr.vg_key}-${nr.vv_key}" => nr }

  vg_private_endpoints = { for pe in flatten([
    for vgk, vgv in var.elastic_san_volume_groups : [
      for pek, pev in vgv.private_link_service_connections : {
        vg_key     = vgk
        pe_key     = pek
        connection = pev
      }
    ]
  ]) : "${pe.vg_key}-${pe.pe_key}" => pe }

}

resource "azapi_resource" "this_elastic_san" {
  type      = "Microsoft.ElasticSan/elasticSans@2023-01-01"
  name      = var.elastic_san_name
  location  = var.location
  parent_id = var.resource_group_id
  tags      = var.tags
  body = {
    properties = {
      availabilityZones       = var.zones
      baseSizeTiB             = var.base_size_in_tib
      extendedCapacitySizeTiB = var.extended_size_in_tib
      publicNetworkAccess     = var.public_network_access
      sku                     = var.sku
    }
  }
}

locals {
  encryptionProperties = { for key, value in var.elastic_san_volume_groups : key => {
    identity = value.encryption_key_vault_properties.user_assigned_managed_identity_resource_id
    keyVaultProperties = {
      keyName     = value.encryption_key_vault_properties.keyName
      keyVaultUri = value.encryption_key_vault_properties.keyVaultUri
      keyVersion  = value.encryption_key_vault_properties.keyVersion
    }
  } if(value.encryption_key_vault_properties != null) }
}

resource "azapi_resource" "this_elastic_san_volume_group" {
  for_each                  = var.elastic_san_volume_groups
  schema_validation_enabled = false

  type      = "Microsoft.ElasticSan/elasticSans/volumegroups@2023-01-01"
  name      = each.value.name
  parent_id = azapi_resource.this_elastic_san.id

  dynamic "identity" {
    for_each = each.value.managed_identities != null ? ["identity"] : []
    content {
      type         = each.value.managed_identities.type
      identity_ids = each.value.managed_identities.identity_ids
    }
  }

  body = jsondecode(each.value.encryption_key_vault_properties != null ? jsonencode({
    properties = {
      encryption           = each.value.encryption_type
      encryptionProperties = local.encryptionProperties
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
}

resource "azapi_resource" "this_elastic_san_volume" {
  for_each = local.vg_volumes

  schema_validation_enabled = false
  type                      = "Microsoft.ElasticSan/elasticSans/volumegroups/volumes@2023-01-01"
  name                      = each.value.volume.name
  parent_id                 = azapi_resource.this_elastic_san_volume_group[each.value.vg_key].id
  body = {
    properties = {
      creationData = {
        createSource = each.value.volume.create_source_source_type
        sourceId     = each.value.volume.create_source_resource_id
      }
      sizeGiB = each.value.volume.size_in_gib
    }
  }

  depends_on = [azurerm_private_endpoint.this]
}

resource "azurerm_private_endpoint" "this" {
  for_each = local.vg_private_endpoints

  name                = each.value.connection.private_endpoint_name
  location            = each.value.connection.resource_group_location
  resource_group_name = each.value.connection.resource_group_name
  subnet_id           = each.value.connection.esan_subnet_resource_id

  private_service_connection {
    name                           = each.value.connection.private_link_service_connection_name
    private_connection_resource_id = azapi_resource.this_elastic_san.id
    subresource_names              = [azapi_resource.this_elastic_san_volume_group[each.value.vg_key].name]
    is_manual_connection           = false
  }
}

/*
resource "azurerm_elastic_san" "this" {
  name                 = var.elastic_san_name
  resource_group_name  = var.resource_group_name
  location             = var.location
  base_size_in_tib     = var.base_size_in_tib
  extended_size_in_tib = var.extended_size_in_tib
  sku {
    name = var.sku.name
    tier = var.sku.tier
  }
  zones = var.zone 
}
*/


/*
resource "azurerm_elastic_san_volume_group" "this" {
  for_each = var.elastic_san_volume_groups

  name            = each.value.name
  elastic_san_id  = azurerm_elastic_san.this.id
  encryption_type = each.value.encryption_type
  protocol_type   = each.value.protocol_type


  dynamic encryption {
    for_each = each.value.encryption != null ? ["encryption"] : []

    content{
        key_vault_key_id          = each.value.encryption.key_vault_key_resource_id
        user_assigned_identity_id = each.value.encryption.user_assigned_identity_resource_id
    }
  }

  dynamic identity {
    for_each = each.value.managed_identities != null ? ["identity"] : []
    content {
        type         = each.value.managed_identities.type
        identity_ids = each.value.managed_identities.identity_ids
    }
  }

  dynamic network_rule {
    for_each = local.vg_network_rules

    content {
        subnet_id = each.value.rule.subnet_id
        action    = each.value.rule.action
    }
  }
}
*/

/*
resource "azurerm_elastic_san_volume" "this" {
  for_each = local.vg_volumes
  
  name            = each.value.volume.name
  volume_group_id = azurerm_elastic_san_volume_group.this[each.value.vg_key].id
  size_in_gib     = each.value.volume.size_in_gib

  dynamic create_source {
    for_each = ( each.value.volume.create_source_resource_id != null && each.value.volume.create_source_source_type != null) ? ["create_source"] : []
    content {
        source_id = each.value.volume.create_source_resource_id
        source_type = each.value.volume.create_source_source_type
    }
  }

  depends_on = [ azurerm_private_endpoint.this ]
}
*/