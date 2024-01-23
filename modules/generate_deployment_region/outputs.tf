locals {
  region = {
    name = "no_quota"
    sku  = "no_quota"
  }
}
#return the deployment region details if quota exists.  Return no_quota if not. (will cause the deployment to error with invalid region)
output "deployment_region" {
  value = try(local.with_quota[random_integer.region_index[0].result], local.region)
}

output "regions_with_quota" {
  value = local.with_quota
}
