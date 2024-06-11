output "resource" {
  description = "The jump vm resource output required by the spec."
  value       = module.jumpvm.resource
}

output "resource_id" {
  description = "The jump vm resource id output required by the spec."
  value       = module.jumpvm.resource_id
}
