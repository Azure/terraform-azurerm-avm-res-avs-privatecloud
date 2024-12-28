locals {
  region = {
    name = "no_quota"
    sku  = "no_quota"
  }
  test_regions = ["eastasia", "eastus2", "germanywestcentral", "qatarcentral", "southafricanorth", "southcentralus", "swedencentral", "uaenorth", "uksouth", "westus2"]
  with_quota   = concat(local.with_quota_av36, local.with_quota_av36p)
  with_quota_av36 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av36" } if
    ((region.output.hostsRemaining.he >= var.total_quota_required) &&
  (try(local.with_quota_av64[split("/", region.resource_id)[6]] == true, false) == true))], [])
  with_quota_av36p = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av36p" } if
    ((region.output.hostsRemaining.he2 >= var.total_quota_required) &&
  (try(local.with_quota_av64[split("/", region.resource_id)[6]] == true, false) == true))], [])
  with_quota_av64 = try({ for av64_region in data.azapi_resource_action.quota : split("/", av64_region.resource_id)[6] => true if(
    (tonumber(av64_region.output.hostsRemaining.av64) >= var.total_av64_quota_required)
  ) }, {})
}

data "azurerm_subscription" "current" {}

#query the quota api for each test region
data "azapi_resource_action" "quota" {
  for_each = toset(local.test_regions)

  type                   = "Microsoft.AVS/locations@2023-09-01"
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