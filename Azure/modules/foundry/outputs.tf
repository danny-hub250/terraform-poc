output "endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "id" {
  value = azurerm_cognitive_account.foundry.id
}

output "name" {
  value = azurerm_cognitive_account.foundry.name

}

output "deployment_name" {
  value = azurerm_cognitive_deployment.chat.name
}

output "primary_access_key" {
  value     = azurerm_cognitive_account.foundry.primary_access_key
  sensitive = true
}