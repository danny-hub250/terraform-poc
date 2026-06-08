output "id" {
  value       = azurerm_linux_virtual_machine.linux_vm.id
  description = "VM 리소스 ID"
}

output "name" {
  value       = azurerm_linux_virtual_machine.linux_vm.name
  description = "VM 이름"
}

output "private_ip_address" {
  value       = azurerm_network_interface.nic.private_ip_address
  description = "VM Private IP"
}

output "public_ip_address" {
  value       = var.enable_public_ip ? azurerm_public_ip.pip[0].ip_address : null
  description = "VM Public IP (enable_public_ip = false 이면 null)"
}
