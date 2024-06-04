
output "volumes" {
  value       = azapi_resource.this_elastic_san_volume
  description = "The full elastic san volume output"
}

output "elastic_san" {
  value       = azapi_resource.this_elastic_san
  description = "The full elastic san resource output."
}

output "resource" {
  value       = azapi_resource.this_elastic_san
  description = "The full elastic san resource output"
}

output "resource_id" {
  value       = azapi_resource.this_elastic_san.id
  description = "The resource id of the elastic san volume"
}