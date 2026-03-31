resource "azurerm_public_ip" "nat" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method   = "Static"
  sku                 = "Standard"

  zones               = var.zones

  tags = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name            = "Standard"

  idle_timeout_in_minutes = var.idle_timeout_in_minutes

  zones               = var.zones

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.create_public_ip ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "this" {
  count = var.public_ip_prefix_id != null ? 1 : 0

  nat_gateway_id      = azurerm_nat_gateway.this.id
  public_ip_prefix_id = var.public_ip_prefix_id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  
  subnet_id      = var.subnet_ids
  nat_gateway_id = azurerm_nat_gateway.this.id
}