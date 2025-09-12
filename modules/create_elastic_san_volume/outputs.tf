output "elastic_san" {
  description = "The full elastic san resource output."
  #value       = jsondecode(azapi_resource.this_elastic_san.output)
  value = azapi_resource.this_elastic_san.output
}

output "resource" {
  description = "The full elastic san resource output"
  #value       = jsondecode(azapi_resource.this_elastic_san.output)
  value = azapi_resource.this_elastic_san.output
}

output "resource_id" {
  description = "The resource id of the elastic san volume"
  value       = azapi_resource.this_elastic_san.id
}

output "volumes" {
  description = "The full elastic san volume output"
  value       = azapi_resource.this_elastic_san_volume
}
