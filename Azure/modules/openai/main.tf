resource "azurerm_cognitive_account" "openai" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  kind     = "OpenAI"
  sku_name = "S0"

  public_network_access_enabled = var.public_network_access_enabled
  custom_subdomain_name = var.custom_subdomain_name
  tags = var.tags
}