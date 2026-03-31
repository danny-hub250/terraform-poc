resource "azurerm_cognitive_account" "foundry" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "AIServices"

  sku_name = "S0"
  custom_subdomain_name = var.name
  tags = var.tags
}