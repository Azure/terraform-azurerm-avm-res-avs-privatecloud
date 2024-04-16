locals {
  nsxt_password    = coalesce(var.nsxt_password, random_password.nsxt.result)
  vcenter_password = coalesce(var.vcenter_password, random_password.vcenter.result)
}


