locals {
  test_regions = var.test_regions

  #get the available quota in all the test regions
  available_quota_by_region_av36p = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av36p", hosts = region.output.hostsRemaining.he2 } if
  (region.output.hostsRemaining.he2 > 0)], [])
  available_quota_by_region_av36 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av36", hosts = region.output.hostsRemaining.he } if
  (region.output.hostsRemaining.he > 0)], [])
  available_quota_by_region_av48 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av48", hosts = region.output.hostsRemaining.hf } if
  (region.output.hostsRemaining.hf > 0)], [])
  available_quota_by_region_av20 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av20", hosts = region.output.hostsRemaining.ge } if
  (region.output.hostsRemaining.ge > 0)], [])
  available_quota_by_region_av64 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av64", hosts = region.output.hostsRemaining.av64 } if
  (region.output.hostsRemaining.av64 > 0)], [])

  #aggregate all the quota types
  available_quota_by_region = concat(local.available_quota_by_region_av36, local.available_quota_by_region_av36p, local.available_quota_by_region_av64, local.available_quota_by_region_av20, local.available_quota_by_region_av48)

  #set a default region of no quota for when no quota is available
  region_empty = {
    generation = var.private_cloud_generation
    name       = "no_quota"
    sku-mgmt   = "no_quota"
    sku-sec    = "no_quota"
  }

  #get regions with Dell quota that match the management cluster size
  with_quota_dell  = { for region, quota in local.available_quota_by_region : "${quota.name}-${quota.sku}" => quota if quota.sku != "av64" }
  with_quota_fleet = { for region, quota in local.available_quota_by_region : "${quota.name}-${quota.sku}" => quota if quota.sku == "av64" }

#get the valid regions for each case
  valid_regions_gen1_dell_only  = var.private_cloud_generation == 1 ? try({ for region, value in local.with_quota_dell : region => { "name" = value.name, "sku-mgmt" = value.sku, "sku-sec" = value.sku, "generation" = 1 } if value.hosts >= (var.management_cluster_quota_required + var.secondary_cluster_quota_required) }, {}) : {}
  valid_regions_gen2_fleet_only = var.private_cloud_generation == 2 ? try({ for region, value in local.with_quota_fleet : region => { "name" = value.name, "sku-mgmt" = value.sku, "sku-sec" = value.sku, "generation" = 2 } if value.hosts >= (var.management_cluster_quota_required + var.secondary_cluster_quota_required) }, {}) : {}
  valid_regions_mixed_dell_fleet = var.private_cloud_generation == 1 ? try({ for region, value in local.with_quota_dell : "${value.name}-${value.sku}-av64" => { "name" = value.name, "sku-mgmt" = value.sku, "sku-sec" = "av64", "generation" = 2 }
  if((value.hosts >= var.management_cluster_quota_required) && try(local.with_quota_fleet["${value.name}-av64"].hosts, 0) >= var.secondary_cluster_quota_required) }, {}) : {}

#merge the valid regions into a single map
  valid_regions = merge(
    local.valid_regions_gen1_dell_only,
    local.valid_regions_gen2_fleet_only,
    local.valid_regions_mixed_dell_fleet
  )

#generate a list of keys to use in the random integer resource
  valid_region_keys = keys(local.valid_regions)
}

data "azurerm_subscription" "current" {}

#query the quota api for each test region
data "azapi_resource_action" "quota" {
  for_each = toset(local.test_regions)

  type                   = "Microsoft.AVS/locations@2024-09-01-preview"
  action                 = "checkQuotaAvailability"
  method                 = "POST"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.AVS/locations/${each.key}"
  response_export_values = ["hostsRemaining"]
}

#generate a random region index if more than one region can satisfy the quota request
resource "random_integer" "region_index" {
  count = length(local.valid_region_keys) > 0 ? 1 : 0
  max = try((length(local.valid_region_keys) - 1), 0)
  min = 0
}

