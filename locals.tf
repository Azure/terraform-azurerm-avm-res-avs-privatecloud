locals {
  nsxt_password                      = coalesce(var.nsxt_password, random_password.nsxt.result)
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
  vcenter_password                   = coalesce(var.vcenter_password, random_password.vcenter.result)
}


