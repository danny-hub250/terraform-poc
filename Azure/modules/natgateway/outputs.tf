output "nat_gateway_id" {
  value = azurerm_nat_gateway.this.id
}

output "public_ip_id" {
  value = try(azurerm_public_ip.nat[0].id, null)
}

output "public_ip_address" {
  value = try(azurerm_public_ip.nat[0].ip_address, null)
}