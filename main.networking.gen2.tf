locals {
  gen2_enabled                     = var.virtual_network_resource_id != null
  gen2_network_resource_group_name = local.gen2_enabled ? element(split("/", var.virtual_network_resource_id), 4) : null
  gen2_udr_gw_config               = try(values(local.gen2_udr_gw_configs)[0], null)
  gen2_udr_gw_configs              = local.gen2_enabled ? { for k, v in var.gen2_subnets_user_defined_routes : k => v if !v.is_mgmnt } : {}
  # This module is designed for a single mgmt and a single gw UDR config.
  gen2_udr_mgmt_config = try(values(local.gen2_udr_mgmt_configs)[0], null)
  # Split the configuration into mgmt and gw configs. The map key is treated as a unique label.
  gen2_udr_mgmt_configs = local.gen2_enabled ? { for k, v in var.gen2_subnets_user_defined_routes : k => v if v.is_mgmnt } : {}
}

# Read all of the subnets in the Gen2 private cloud VNet. These subnets are created/managed by AVS.
data "azapi_resource_list" "gen2_subnets" {
  count = local.gen2_enabled ? 1 : 0

  parent_id              = var.virtual_network_resource_id
  type                   = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  response_export_values = ["value"]

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_update_resource.dns_default_service_ips,
    azapi_resource.dhcp,
    azapi_resource.segments
  ]
}

locals {
  # AVS-managed subnet identification
  gen2_mgmt_subnets = {
    for name, subnet in local.gen2_subnets : name => {
      id             = subnet.id
      route_table_id = try(subnet.properties.routeTable.id, null)
    } if startswith(lower(name), "avs-mgmt-")
  }
  gen2_nsx_gw_subnets = {
    for name, subnet in local.gen2_subnets : name => {
      id = subnet.id
    } if startswith(lower(name), "avs-nsx-gw-")
  }
  gen2_subnets = { for s in try(data.azapi_resource_list.gen2_subnets[0].output.value, []) : s.name => s }
}

# Read the user defined route table for the mgmt subnet(s) (if UDR config is defined)
data "azapi_resource" "gen2_mgmt_route_table" {
  for_each = (local.gen2_enabled && local.gen2_udr_mgmt_config != null) ? toset(distinct(compact([for s in values(local.gen2_mgmt_subnets) : s.route_table_id]))) : toset([])

  resource_id            = each.key
  type                   = "Microsoft.Network/routeTables@2024-05-01"
  response_export_values = ["*"]

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_update_resource.dns_default_service_ips,
    azapi_resource.dhcp,
    azapi_resource.segments,
    data.azapi_resource_list.gen2_subnets
  ]
}

locals {
  gen2_udr_mgmt_custom_routes = local.gen2_udr_mgmt_config == null ? {} : {
    for route_name, route in local.gen2_udr_mgmt_config.routes : lower(route_name) => {
      name = route_name
      properties = {
        addressPrefix    = route.address_prefix
        nextHopType      = route.next_hop_type
        nextHopIpAddress = try(route.next_hop_in_ip_address, null)
      }
    }
  }
}

# Modify the service-created mgmt route table by merging in the user-defined routes
resource "azapi_update_resource" "gen2_mgmt_route_table" {
  for_each = data.azapi_resource.gen2_mgmt_route_table

  resource_id = each.key
  type        = "Microsoft.Network/routeTables@2024-05-01"
  body = {
    properties = {
      disableBgpRoutePropagation = !(try(local.gen2_udr_mgmt_config.bgp_route_propagation_enabled, true))
      routes = [
        for r in values(merge(
          { for existing in try(each.value.output.properties.routes, []) : lower(existing.name) => existing },
          local.gen2_udr_mgmt_custom_routes
          )) : {
          name = r.name
          properties = {
            addressPrefix    = r.properties.addressPrefix
            nextHopType      = r.properties.nextHopType
            nextHopIpAddress = try(r.properties.nextHopIpAddress, null)
          }
        }
      ]
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_update_resource.dns_default_service_ips,
    azapi_resource.dhcp,
    azapi_resource.segments,
    data.azapi_resource_list.gen2_subnets,
    data.azapi_resource.gen2_mgmt_route_table
  ]
}


# Create new User defined route table for the gen2 AVS avs-nsx-gw-* subnets if defined
resource "azurerm_route_table" "gen2_nsx_gw_udr" {
  count = (local.gen2_enabled && local.gen2_udr_gw_config != null) ? 1 : 0

  location                      = var.location
  name                          = coalesce(try(local.gen2_udr_gw_config.name, null), "${var.name}-avs-nsx-gw-udr")
  resource_group_name           = local.gen2_network_resource_group_name
  bgp_route_propagation_enabled = try(local.gen2_udr_gw_config.bgp_route_propagation_enabled, true)
  tags                          = var.tags

  dynamic "route" {
    for_each = local.gen2_udr_gw_config == null ? {} : local.gen2_udr_gw_config.routes

    content {
      address_prefix         = route.value.address_prefix
      name                   = route.key
      next_hop_in_ip_address = try(route.value.next_hop_in_ip_address, null)
      next_hop_type          = route.value.next_hop_type
    }
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_update_resource.dns_default_service_ips,
    azapi_resource.dhcp,
    azapi_resource.segments,
    data.azapi_resource_list.gen2_subnets,
    data.azapi_resource.gen2_mgmt_route_table,
    azapi_update_resource.gen2_mgmt_route_table
  ]
}

# Attach the GW UDR to both AVS NSX GW subnets
resource "azapi_update_resource" "gen2_nsx_gw_subnet_udr_association" {
  for_each = (local.gen2_enabled && local.gen2_udr_gw_config != null) ? local.gen2_nsx_gw_subnets : {}

  resource_id = each.value.id
  type        = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      routeTable = {
        id = azurerm_route_table.gen2_nsx_gw_udr[0].id
      }
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_update_resource.dns_default_service_ips,
    azapi_resource.dhcp,
    azapi_resource.segments,
    data.azapi_resource_list.gen2_subnets,
    data.azapi_resource.gen2_mgmt_route_table,
    azapi_update_resource.gen2_mgmt_route_table,
    azurerm_route_table.gen2_nsx_gw_udr
  ]
}
