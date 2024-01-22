/*
output "quota_available" {
    value = local.region_with_quota_exists
}

output "fulloutput" {
  value = data.azapi_resource_action.quota
}

output "av36"{ 
    value = local.with_quota_av36
}

output "av36p"{
    value = local.with_quota_av36p
}
*/

locals {
  region = {
    name = "no_quota"
    sku  = "no_quota"
  }
}
output "deployment_region" {
  value = try(local.with_quota[random_integer.region_index[0].result], local.region)
}

output "regions_with_quota" {
  value = local.with_quota
}