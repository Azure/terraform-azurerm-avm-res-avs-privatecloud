#create a trigger data resource that changes when the input changes
resource "terraform_data" "rerun_get" {
  triggers_replace = var.vcenter_identity_sources
}

#####################################################################################################################################
# Remove Existing Source
#####################################################################################################################################
#on first run this will error? (future runs will remove as expected?)
#if a config exists and they don't match, remove the existing configuration.
#trigger on a config change by the data source
resource "azapi_resource" "remove_existing_identity_source" {
  for_each = var.vcenter_identity_sources

  name      = "TF-AVM-RemoveIdentitySources-${each.key}"
  parent_id = azapi_resource.this_private_cloud.id
  type      = "Microsoft.AVS/privateClouds/scriptExecutions@2024-09-01"
  #Set the body to remove the domain if the conditions match, otherwise just run the get.
  body = ({ #remove the current identity source
    properties = {
      timeout        = "PT15M"
      retention      = "P30D"
      scriptCmdletId = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*/scriptCmdlets/Remove-ExternalIdentitySources"
      DomainName     = each.value.domain
    }
    }
  )
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values    = ["*"]
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_express_route_connection.avs_private_cloud_connection_additional,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection,
    azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional,
    azapi_resource.globalreach_connections,
    azapi_resource.avs_interconnect,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service,
    azapi_resource.dhcp,
    azapi_resource.segments,
    #azapi_resource.current_status_identity_sources
  ]

  lifecycle {
    ignore_changes       = [body]
    replace_triggered_by = [terraform_data.rerun_get]
  }
}


#####################################################################################################################################
# Configure LDAP(s)
#####################################################################################################################################
resource "azapi_resource" "configure_identity_sources" {
  for_each = var.vcenter_identity_sources

  name      = "TF-AVM-SetIdentitySources-${each.key}"
  parent_id = azapi_resource.this_private_cloud.id
  type      = "Microsoft.AVS/privateClouds/scriptExecutions@2023-09-01"
  body = ({
    properties = {
      timeout        = "PT15M"
      retention      = "P30D"
      scriptCmdletId = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*/scriptCmdlets/${each.value.ssl == "Enabled" ? "New-LDAPSIdentitySource" : "New-LDAPIdentitySource"}"
      hiddenParameters = [{
        name     = "Credential"
        type     = "Credential"
        username = var.vcenter_identity_sources_credentials[each.key].ldap_user
        password = var.vcenter_identity_sources_credentials[each.key].ldap_user_password
      }]
      parameters = each.value.secondary_server != null ? [ #list with a primary and secondary server value
        {
          name  = "GroupName"
          type  = "Value"
          value = each.value.group_name
        },
        {
          name  = "BaseDNGroups"
          type  = "Value"
          value = each.value.base_group_dn
        },
        {
          name  = "BaseDNUsers"
          type  = "Value"
          value = each.value.base_user_dn
        },
        {
          name  = "PrimaryUrl"
          type  = "Value"
          value = each.value.primary_server
        },
        {
          name  = "DomainAlias"
          type  = "Value"
          value = each.value.alias
        },
        {
          name  = "DomainName"
          type  = "Value"
          value = each.value.domain
        },
        {
          name  = "Name"
          type  = "Value"
          value = each.value.name
        },
        {
          name  = "SecondaryUrl"
          type  = "Value"
          value = each.value.secondary_server
        }
        ] : [ #list with only a primary value
        {
          name  = "GroupName"
          type  = "Value"
          value = each.value.group_name
        },
        {
          name  = "BaseDNGroups"
          type  = "Value"
          value = each.value.base_group_dn
        },
        {
          name  = "BaseDNUsers"
          type  = "Value"
          value = each.value.base_user_dn
        },
        {
          name  = "PrimaryUrl"
          type  = "Value"
          value = each.value.primary_server
        },
        {
          name  = "DomainAlias"
          type  = "Value"
          value = each.value.alias
        },
        {
          name  = "DomainName"
          type  = "Value"
          value = each.value.domain
        },
        {
          name  = "Name"
          type  = "Value"
          value = each.value.name
        }
      ]
    }
  })
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = "4h"
    delete = "4h"
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
    azapi_resource.dhcp,
    azapi_resource.segments,
    #azapi_resource.current_status_identity_sources,
    azapi_resource.remove_existing_identity_source
  ]

  lifecycle {
    ignore_changes       = [body]
    replace_triggered_by = [terraform_data.rerun_get]
  }
}
