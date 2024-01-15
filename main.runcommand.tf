#Get the list of previously executed run commands
data "azapi_resource_list" "avs_run_command_executions" {
  type                   = "Microsoft.AVS/privateClouds/scriptExecutions@2022-05-01"
  parent_id              = azapi_resource.this_private_cloud.id
  response_export_values = ["value"]
}

#get a list of the current Microsoft Runcommands
data "azapi_resource_list" "valid_run_commands_microsoft_avs" {
  type = "Microsoft.AVS/privateClouds/scriptPackages/scriptCmdlets@2022-05-01"
  #resource_id            = "/subscriptions/d52f9c4a-5468-47ec-9641-da4ef1916bb5/resourceGroups/rg-drtd/providers/Microsoft.AVS/privateClouds/avs-sddc-drtd/workloadNetworks/default/dnsServices"
  parent_id              = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*"
  response_export_values = ["value"]
  #method                 = "GET"
}

#Generate a list of indexes for the current known run commands.  Set the index to 0 if the run command doesn't have a current run
locals {
  valid_run_commands_microsoft_avs  = [for k, v in jsondecode(data.azapi_resource_list.valid_run_commands_microsoft_avs.output).value[*] : v.name]
  run_command_microsoft_avs_indexes = { for k, v in local.valid_run_commands_microsoft_avs : v => (try(max([for value in jsondecode(data.azapi_resource_list.avs_run_command_executions.output).value[*].name : tonumber(split("-Exec", value)[1]) if strcontains(value, v)]...), 0)) }
}

#TODO: Add a general resource for processing additional run commands?