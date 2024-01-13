# TODO: insert locals here.
locals {
  #set the resource deployment location. Default to the resource group location
  location         = coalesce(var.location, data.azurerm_resource_group.sddc_deployment.location)
  nsxt_password    = coalesce(var.nsxt_password, random_password.nsxt.result)
  vcenter_password = coalesce(var.vcenter_password, random_password.vcenter.result)


  #run command related locals
  #run_command_version_microsoft = "Microsoft.AVS.Management@5.3.99"
  #LDAPs Prefix and increment the last run execution index by 1
  #prefix_configure_ldaps = "New-LDAPSIdentitySource"
  #index_configure_ldaps = (try(max([ for value in jsondecode(data.azapi_resource_list.avs_runcommand_new_ldaps.output).value[*].name : tonumber(split("-Exec", value)[1]) if strcontains(value, local.prefix_configure_ldaps) ]...), 0)) + 1
}


