output "resource" {
  value = module.jumpvm.resource
  description = "The jump vm resource output required by the spec."
}

output "resource_id" {
  value = module.jumpvm.resource_id
  description = "The jump vm resource id output required by the spec."
}
