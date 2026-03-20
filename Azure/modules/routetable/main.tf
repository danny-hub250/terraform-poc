resource "azurerm_route_table" "routetable" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_route" "routes" {
  for_each = var.routes

  name                   = each.key
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.routetable.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = lookup(each.value, "next_hop_ip", null)
}

resource "azurerm_subnet_route_table_association" "assoc" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.routetable.id
}