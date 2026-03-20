module "onprem-rg" {

  source = "../../modules/resourcegroup"

  name     = "koo-onprem-rg"
  location = var.location

  tags = var.tags

}

module "azure-rg" {

  source = "../../modules/resourcegroup"

  name     = "koo-azure-rg"
  location = var.location

  tags = var.tags

}

module "onprem-vnet" {

  source = "../../modules/virtualnetwork"

  name                = "onprem-vnet"
  location            = var.location
  resource_group_name = module.onprem-rg.name

  address_space = ["10.10.0.0/22"]

}

module "subnet_onpremvpn" {

  source = "../../modules/subnet"

  name                = "GatewaySubnet"
  resource_group_name = module.onprem-rg.name
  vnet_name           = module.onprem-vnet.name

  address_prefixes = ["10.10.0.0/24"]

}

module "azure-vnet" {

  source = "../../modules/virtualnetwork"

  name                = "azure-vnet"
  location            = var.location
  resource_group_name = module.azure-rg.name

  address_space = ["10.10.4.0/22"]

}

module "subnet_azurevpn" {

  source = "../../modules/subnet"

  name                = "GatewaySubnet"
  resource_group_name = module.azure-rg.name
  vnet_name           = module.azure-vnet.name

  address_prefixes = ["10.10.4.0/24"]

}


module "subnet_azfw" {

  source = "../../modules/subnet"

  name                = "AzureFirewallSubnet"
  resource_group_name = module.azure-rg.name
  vnet_name           = module.azure-vnet.name

  address_prefixes = ["10.10.5.0/25"]

}

module "subnet_azfwmgmt" {

  source = "../../modules/subnet"

  name                = "AzureFirewallManagementSubnet"
  resource_group_name = module.azure-rg.name
  vnet_name           = module.azure-vnet.name

  address_prefixes = ["10.10.5.128/25"]

}



