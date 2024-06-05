
output "volumes" {
  value       = azapi_resource.this_elastic_san_volume
  description = "The full elastic san volume output"
}

output "elastic_san" {
  value       = jsondecode(azapi_resource.this_elastic_san.output)
  description = "The full elastic san resource output."
}

output "resource" {
  value       = jsondecode(azapi_resource.this_elastic_san.output)
  description = "The full elastic san resource output"
}

output "resource_id" {
  value       = jsondecode(azapi_resource.this_elastic_san.output).id
  description = "The resource id of the elastic san volume"
}