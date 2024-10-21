output "hcx_cloud_manager_endpoint_hostname" {
  description = "The hcx cloud manager hostname"
  value       = module.test_private_cloud.hcx_cloud_manager_endpoint_hostname
}

output "hcx_cloud_manager_endpoint_https" {
  value = module.test_private_cloud.hcx_cloud_manager_endpoint_https
}

output "nsxt_manager_endpoint_hostname" {
  description = "The nsxt endpoint hostname"
  value       = module.test_private_cloud.nsxt_manager_endpoint_hostname
}

output "nsxt_manager_endpoint_https" {
  value = module.test_private_cloud.nsxt_manager_endpoint_https
}

output "resource" {
  description = "Example output of the full private cloud resource output."
  value       = module.test_private_cloud.resource
}

output "vcsa_endpoint_hostname" {
  description = "The vcsa endpoint hostname"
  value       = module.test_private_cloud.vcsa_endpoint_hostname
}

output "vcsa_endpoint_https" {
  description = "The https endpoint for vcsa"
  value       = module.test_private_cloud.vcsa_endpoint_https
}
