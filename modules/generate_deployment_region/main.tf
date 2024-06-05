locals {
  test_regions     = ["southafricanorth", "eastasia", "canadacentral", "germanywestcentral"]
  with_quota       = concat(local.with_quota_av36, local.with_quota_av36p)
  with_quota_av36  = try([for region in jsondecode(data.azapi_resource_action.quota) : { name = split("/", region.resource_id)[6], sku = "av36" } if region.output.hostsRemaining.he >= var.total_quota_required], [])
  with_quota_av36p = try([for region in jsondecode(data.azapi_resource_action.quota) : { name = split("/", region.resource_id)[6], sku = "av36p" } if region.output.hostsRemaining.he2 >= var.total_quota_required], [])
}

data "azurerm_subscription" "current" {}

#query the quota api for each test region
data "azapi_resource_action" "quota" {
  for_each = toset(local.test_regions)

  type                   = "Microsoft.AVS/locations@2023-03-01"
  action                 = "checkQuotaAvailability"
  method                 = "POST"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.AVS/locations/${each.key}"
  response_export_values = ["hostsRemaining"]
}

#generate a random region index if more than one region can satisfy the quota request
resource "random_integer" "region_index" {
  count = try((length(local.with_quota) > 0), false) ? 1 : 0 #fails if we don't have quota

  max = try((length(local.with_quota) - 1), 0)
  min = 0
}
