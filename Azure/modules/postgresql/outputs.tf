output "id" {
  value       = azurerm_postgresql_flexible_server.postgresql.id
  description = "PostgreSQL Flexible Server 리소스 ID"
}

output "name" {
  value       = azurerm_postgresql_flexible_server.postgresql.name
  description = "PostgreSQL Flexible Server 이름"
}

output "fqdn" {
  value       = azurerm_postgresql_flexible_server.postgresql.fqdn
  description = "PostgreSQL Flexible Server FQDN"
}
