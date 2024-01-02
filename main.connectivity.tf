#create the expressRoute auth keys to use for ExpressRoute gateway connections
resource "azurerm_vmware_express_route_authorization" "this_authorization_key" {
  for_each = var.expressroute_connections

  name             = each.value.authorization_key_name == null ? "${each.key}-auth-key" : each.value.authorization_key_name
  private_cloud_id = azapi_resource.this_private_cloud.id
}

#create one or more global reach connections
resource "azapi_resource" "globalreach_connections" {
  for_each = var.global_reach_connections

  type      = "Microsoft.AVS/privateClouds/globalReachConnections@2022-05-01"
  name      = each.key
  parent_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      authorizationKey        = each.value.authorization_key
      peerExpressRouteCircuit = each.value.peer_expressroute_circuit_resource_id
    }
  })
}

#create one or more ExpressRoute Gateway connections to virtual network hubs
resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = { for k, v in var.expressroute_connections : k => v if v.vwan_hub_connection == false }

  type                         = "ExpressRoute"
  enable_bgp                   = true
  name                         = each.key
  location                     = local.location
  resource_group_name          = data.azurerm_resource_group.sddc_deployment.name
  express_route_gateway_bypass = each.value.fast_path_enabled

  authorization_key          = azurerm_vmware_express_route_authorization.this_authorization_key[each.key].express_route_authorization_key
  virtual_network_gateway_id = each.value.expressroute_gateway_resource_id
  express_route_circuit_id   = jsondecode(azapi_resource.this_private_cloud.output).properties.circuit.expressRouteID
}

#Create one or more ExpressRoute Gateway connections to a VWAN hub
resource "azurerm_express_route_connection" "avs_private_cloud_connection" {
  for_each = { for k, v in var.expressroute_connections : k => v if v.vwan_hub_connection == true }

  name                             = each.key
  express_route_gateway_id         = each.value.expressroute_gateway_resource_id
  express_route_circuit_peering_id = jsondecode(azapi_resource.this_private_cloud.output).properties.circuit.expressRouteID
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
}
