#Get the list of previously executed run commands
data "azapi_resource_list" "avs_run_command_executions" {
  parent_id              = azapi_resource.this_private_cloud.id
  type                   = "Microsoft.AVS/privateClouds/scriptExecutions@2023-03-01"
  response_export_values = ["value"]
}

#get a list of the current Microsoft Runcommands
data "azapi_resource_list" "valid_run_commands_microsoft_avs" {
  parent_id              = "${azapi_resource.this_private_cloud.id}/scriptPackages/Microsoft.AVS.Management@*"
  type                   = "Microsoft.AVS/privateClouds/scriptPackages/scriptCmdlets@2023-03-01"
  response_export_values = ["value"]
}

#Generate a list of indexes for the current known run commands.  Set the index to 0 if the run command doesn't have a current run
locals {
  run_command_microsoft_avs_indexes = { for k, v in local.valid_run_commands_microsoft_avs : v => (try(max([for value in data.azapi_resource_list.avs_run_command_executions.output.value[*].name : tonumber(split("-Exec", value)[1]) if strcontains(value, v)]...), 0)) }
  valid_run_commands_microsoft_avs  = [for k, v in data.azapi_resource_list.valid_run_commands_microsoft_avs.output.value[*] : v.name]
}

#TODO: Add a general resource for processing additional run commands?
