#get the current identity sources configuration
resource "azapi_resource" "current_status_identity_sources" {
  type      = "Microsoft.AVS/privateClouds/scriptExecutions@2022-05-01"
  name      = "Get-ExternalIdentitySources-Exec${tostring(tonumber(local.run_command_microsoft_avs_indexes["Get-ExternalIdentitySources"]) + 1)}" #increment the index number for the run command name using indexes
  parent_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      timeout        = "PT15M"
      retention      = "P30D"
      scriptCmdletId = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*/scriptCmdlets/Get-ExternalIdentitySources"
    }
  })
  response_export_values = ["*"]
}

#Configure the identity source(s)

locals {
  # API output is a heredoc string of the field values. Split the string into separate list elements and remove the whitespaces.
  parsed_identity_sources          = try([for value in split("\n", tostring(jsondecode(azapi_resource.current_status_identity_sources.output).properties.output[1])) : split(": ", value) if strcontains(value, ": ")], [])
  cleaned_identity_sources_to_list = try([for value in local.parsed_identity_sources : [for item in value : trimspace(item)]], [])
  cleaned_identity_sources_to_map  = try({ for value in local.cleaned_identity_sources_to_list : value[0] => value[1] })


  #do the comparison
  #loop through each element in the vcenter_identity_sources map (assumes only one identity source config (TODO: test and modify to add multiple sources))
  identity_matches = { for k, v in var.vcenter_identity_sources : k => false if( #set the key to false if any of the core values don't match
    try(v.primary_server, null) != try(local.cleaned_identity_sources_to_map["PrimaryUrl"], null) ||
    try(v.secondary_server, null) != try(local.cleaned_identity_sources_to_map["FailoverUrl"], null) ||
    try(v.base_group_dn, null) != try(local.cleaned_identity_sources_to_map["GroupBaseDN"], null) ||
    try(v.base_user_dn, null) != try(local.cleaned_identity_sources_to_map["UserBaseDN"], null) ||
    try(var.ldap_user, null) != try(local.cleaned_identity_sources_to_map["AuthenticationUsername"], null) ||
    try(v.name, null) != try(local.cleaned_identity_sources_to_map["Name"], null)
  ) }
}

#####################################################################################################################################
# Configure LDAPS
#####################################################################################################################################
resource "azapi_resource" "configure_ldaps" {
  #for_each = {for k,v in var.vcenter_identity_sources : k =>v if local.identity_matches[k] == false }
  for_each = var.vcenter_identity_sources

  type = "Microsoft.AVS/privateClouds/scriptExecutions@2021-06-01"
  # if SSL is enabled use the LDAPS cmdlet, else use the LDAP cmdlet
  name = ( local.identity_matches[each.key] == false ?
    (
      each.value.ssl == "Enabled" ?
        "New-LDAPSIdentitySource-Exec${tostring(tonumber(local.run_command_microsoft_avs_indexes["New-LDAPSIdentitySource"]) + 1)}" :
        "New-LDAPIdentitySource-Exec${tostring(tonumber(local.run_command_microsoft_avs_indexes["New-LDAPIdentitySource"]) + 1)}"
    ) :
    (
      "Get-ExternalIdentitySources-Exec${tostring(tonumber(local.run_command_microsoft_avs_indexes["Get-ExternalIdentitySources"]) + 1)}")
    )
  parent_id = azapi_resource.this_private_cloud.id
  body = ( local.identity_matches[each.key] == false ?
    ( #Nothing needs to change, run the get action
      jsonencode({
        properties = {
          timeout        = "PT15M"
          retention      = "P30D"
          scriptCmdletId = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*/scriptCmdlets/Get-ExternalIdentitySources"
        }
    })
    ) : #else update the configuration with the new values
    (
      jsonencode({
        properties = {
          timeout        = "PT15M"
          retention      = "P30D"
          scriptCmdletId = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*/scriptCmdlets/${each.value.ssl == "Enabled" ? "New-LDAPSIdentitySource" : "New-LDAPIdentitySource"}"
          hiddenParameters = [{
            name     = "Credential"
            type     = "Credential"
            username = var.ldap_user
            password = var.ldap_user_password
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
    )
  )
  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azurerm_express_route_connection.avs_private_cloud_connection,
    azurerm_virtual_network_gateway_connection.this,
    azapi_resource.dns_forwarder_zones,
    azapi_resource_action.dns_service
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}
