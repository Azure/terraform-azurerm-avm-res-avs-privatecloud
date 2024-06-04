output "resource" {
  description = "the full ANF volume resource being created."
  value       = azurerm_netapp_volume.anf_volume
}

output "resource_id" {
  description = "The Azure resource ID of the netapp volume being created."
  value       = azurerm_netapp_volume.anf_volume.id
}

output "volume_id" {
  description = "The Azure resource ID of the netapp volume being created."
  value       = azurerm_netapp_volume.anf_volume.id
}
