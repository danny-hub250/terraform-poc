resource "azurerm_network_interface" "nic" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_password = var.admin_password
  disable_password_authentication = false
  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = var.tags
}