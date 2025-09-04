#return the deployment region details if quota exists.  Return no_quota if not. (will cause the deployment to error with invalid region)
output "deployment_region" {
  description = "The region map to use for the AVS deployment. Returns no_quota if all region quota is consumed."
  value       = try(local.valid_regions[local.valid_region_keys[random_integer.region_index[0].result]], local.region_empty)
}

output "regions" {
  description = "A map of regions with quota counts."
  value       = local.available_quota_by_region
}

output "regions_with_quota" {
  description = "A map of regions that meet the quota requirement."
  value       = local.valid_regions
}

output "resource" {
  description = "The region map to use for the AVS deployment. Returns no_quota if all region quota is consumed. Duplicating the deployment region output to comply with the AVM spec."
  value       = try(local.valid_regions[local.valid_region_keys[random_integer.region_index[0].result]], local.region_empty)
}

output "resource_id" {
  description = "A map of regions that meet the quota requirement. Duplicating the regions with quota output to comply with the AVM spec."
  value       = local.valid_regions
}
