locals {
  gen2_effective_config              = try(values(var.gen2_private_cloud)[0], null)
  gen2_effective_enabled             = length(var.gen2_private_cloud) > 0 || var.virtual_network_resource_id != null
  gen2_effective_virtual_network_id  = try(local.gen2_effective_config.virtual_network_resource_id, var.virtual_network_resource_id)
  nsxt_password                      = coalesce(var.nsxt_password, random_password.nsxt.result)
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
  vcenter_password                   = coalesce(var.vcenter_password, random_password.vcenter.result)
}
