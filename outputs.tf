# TODO: insert outputs here.
output "private_cloud" {
  value = jsondecode(azapi_resource.this_private_cloud.output)
}

output "credentials" {
  value     = jsondecode(data.azapi_resource_action.sddc_creds.output)
  sensitive = true
}
