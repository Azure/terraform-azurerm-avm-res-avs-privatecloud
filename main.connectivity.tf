#create the expressRoute auth keys to use for ExpressRoute gateway connections
resource "azurerm_vmware_express_route_authorization" "this_authorization_key" {
  for_each = var.expressroute_connections

  name             = each.value.authorization_key_name == null ? "${each.key}-auth-key" : each.value.authorization_key_name
  private_cloud_id = azapi_resource.this_private_cloud.id
}

#create one or more global reach connections
resource "azapi_resource" "globalreach_connections" {
  for_each = var.global_reach_connections

  type = "Microsoft.AVS/privateClouds/globalReachConnections@2023-03-01"
  body = {
    properties = {
      authorizationKey        = each.value.authorization_key
      peerExpressRouteCircuit = each.value.peer_expressroute_circuit_resource_id
    }
  }
  name      = each.key
  parent_id = azapi_resource.this_private_cloud.id

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon
  ]
}

data "azurerm_vmware_private_cloud" "this_private_cloud" {
  name                = azapi_resource.this_private_cloud.name
  resource_group_name = data.azurerm_resource_group.sddc_deployment.name
}

/*
#create one or more ExpressRoute Gateway connections to virtual network hubs
resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = { for k, v in var.expressroute_connections : k => v if v.vwan_hub_connection == false }

  location                     = var.location
  name                         = each.key
  resource_group_name          = data.azurerm_resource_group.sddc_deployment.name
  type                         = "ExpressRoute"
  virtual_network_gateway_id   = each.value.expressroute_gateway_resource_id
  authorization_key            = azurerm_vmware_express_route_authorization.this_authorization_key[each.key].express_route_authorization_key
  enable_bgp                   = true
  express_route_circuit_id     = azapi_resource.this_private_cloud.output.properties.circuit.expressRouteID
  express_route_gateway_bypass = each.value.fast_path_enabled
  tags                         = each.value.tags == {} ? var.tags : each.value.tags

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azapi_resource.globalreach_connections
  ]

  lifecycle {
    ignore_changes = [express_route_circuit_id]
  } #TODO - determine why this is returning 'known after apply'
}
*/

#create one or more ExpressRoute Gateway connections to virtual network hubs
resource "azapi_resource" "avs_private_cloud_expressroute_vnet_gateway_connection" {
  for_each = { for k, v in var.expressroute_connections : k => v if v.vwan_hub_connection == false }

  type = "Microsoft.Network/connections@2023-11-01"
  body = {
    properties = {
      connectionType = "ExpressRoute"
      virtualNetworkGateway1 = {
        properties = {
        }
        id = each.value.expressroute_gateway_resource_id
      }
      authorizationKey          = azurerm_vmware_express_route_authorization.this_authorization_key[each.key].express_route_authorization_key
      expressRouteGatewayBypass = each.value.fast_path_enabled
      enablePrivateLinkFastPath = each.value.private_link_fast_path_enabled
      peer = {
        id = azapi_resource.this_private_cloud.output.properties.circuit.expressRouteID
      }
    }
  }
  location  = coalesce(each.value.network_resource_group_location, var.location)
  name      = each.value.name
  parent_id = coalesce(each.value.network_resource_group_resource_id, var.resource_group_resource_id)
  tags      = each.value.tags == {} ? var.tags : each.value.tags

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azapi_resource.globalreach_connections
  ]
}


#Create one or more ExpressRoute Gateway connections to a VWAN hub
resource "azurerm_express_route_connection" "avs_private_cloud_connection" {
  for_each = { for k, v in var.expressroute_connections : k => v if v.vwan_hub_connection == true }

  express_route_circuit_peering_id = data.azurerm_vmware_private_cloud.this_private_cloud.circuit[0].express_route_private_peering_id
  express_route_gateway_id         = each.value.expressroute_gateway_resource_id
  name                             = each.key
  authorization_key                = azurerm_vmware_express_route_authorization.this_authorization_key[each.key].express_route_authorization_key
  enable_internet_security         = each.value.enable_internet_security #publish a default route to the internet through Hub NVA when true
  routing_weight                   = each.value.routing_weight

  dynamic "routing" {
    for_each = each.value.routing

    content {
      associated_route_table_id = routing.value.associated_route_table_id
      inbound_route_map_id      = routing.value.inbound_route_map_id
      outbound_route_map_id     = routing.value.outbound_route_map_id

      propagated_route_table {
        labels          = routing.value.propagated_route_table.labels
        route_table_ids = routing.value.propagated_route_table.route_table_ids
      }
    }
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azapi_resource.globalreach_connections,
    #azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection
  ]

  lifecycle {
    ignore_changes = [express_route_circuit_peering_id]
  } #TODO - determine why this is returning 'known after apply'
}

#create one or more cross SDDC regional connections
resource "azapi_resource" "avs_interconnect" {
  for_each = var.avs_interconnect_connections

  type = "Microsoft.AVS/privateClouds/cloudLinks@2023-03-01"
  body = {
    properties = {
      linkedCloud = each.value.linked_private_cloud_resource_id
    }
  }
  name      = each.key
  parent_id = azapi_resource.this_private_cloud.id

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azurerm_express_route_connection.avs_private_cloud_connection
  ]
}
