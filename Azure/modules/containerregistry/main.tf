resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # 네트워크 접근 제어
  public_network_access_enabled = var.public_network_access_enabled

  # Private Endpoint 쓸거면 보통 false
  network_rule_bypass_option = "AzureServices"

  tags = var.tags
}