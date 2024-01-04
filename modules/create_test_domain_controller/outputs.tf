output "dc_details" {
    value = data.azurerm_virtual_machine.this_vm
    sensitive = false
}