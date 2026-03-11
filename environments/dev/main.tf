module "rg" {

  source = "../../modules/resourcegroup"

  name     = "platform-dev-rg"
  location = var.location

  tags = var.tags

}

module "vnet" {

  source = "../../modules/vnet"

  name                = "platform-dev-vnet"
  location            = var.location
  resource_group_name = module.rg.name

  address_space = ["10.10.0.0/16"]

}

module "subnet_aks" {

  source = "../../modules/subnet"

  name                = "aks-subnet"
  resource_group_name = module.rg.name
  vnet_name           = module.vnet.vnet_name

  address_prefixes = ["10.10.1.0/24"]

}

module "subnet_private_endpoint" {

  source = "../../modules/subnet"

  name                = "private-endpoint-subnet"
  resource_group_name = module.rg.name
  vnet_name           = module.vnet.vnet_name

  address_prefixes = ["10.10.2.0/24"]

}