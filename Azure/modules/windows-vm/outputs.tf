output "id" {
  description = "The ID of the Windows Virtual Machine"
  value       = azurerm_windows_virtual_machine.windows_vm.id
}

output "private_ip_address" {
  description = "The private IP address of the Windows Virtual Machine"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "nic_id" {
  description = "The ID of the Network Interface"
  value       = azurerm_network_interface.nic.id
}
