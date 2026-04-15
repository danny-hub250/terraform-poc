

module "koo-rg" {
  source = "../../modules/resourcegroup"
  name                = "bonahkoo-rg"
  location            = var.location
  tags                = var.tags
}

module "vnet" {
  source = "../../modules/virtualnetwork"
  name                = "bonahkoo-vnet"
  location            = var.location
  resource_group_name = module.koo-rg.name
  address_space       = ["10.20.0.0/16"]
  tags                = var.tags
}

module "subnet_aks" {
  source = "../../modules/subnet"
  name                = "aks-snet"
  resource_group_name = module.koo-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.20.1.0/24"]
}

module "subnet_private_endpoint" {
  source = "../../modules/subnet"
  name                = "pe-snet"
  resource_group_name = module.koo-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.20.2.0/24"]
}

module "subnet_vm" {
  source = "../../modules/subnet"
  name                = "vm-snet"
  resource_group_name = module.koo-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.20.3.0/24"]
}
# module "nat_gateway" {
#   source = "../../modules/natgateway"
#   name                = "koo-natgw"
#   location            = var.location
#   resource_group_name = module.koo-rg.name
#   subnet_ids          = module.subnet_aks.id
#   tags                = var.tags
# }

module "linux-vm" {
  source = "../../modules/linux-vm"
  name                = "koo-vm"
  resource_group_name = module.koo-rg.name
  location            = var.location
  subnet_id           = module.subnet_aks.id
  size                = "Standard_D2ds_v5"
  admin_password      = "Azure2023!!!"
  storage_account_type = "Standard_LRS"
  disk_size_gb = 30
  tags = var.tags
}


module "windows-vm" {
  source = "../../modules/windows-vm"
  name                = "koo-win-vm"
  computer_name       = "koo-win-vm"
  resource_group_name = module.koo-rg.name
  location            = var.location
  subnet_id           = module.subnet_vm.id
  size                = "Standard_D2ds_v5"
  admin_password      = "Azure2023!!!"
  storage_account_type = "Standard_LRS"
  disk_size_gb        = 128
  image_sku           = "2022-Datacenter"
  tags                = var.tags
}

module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name = "koo-aks"
  
  system_node_pool = {
    name       = "sysnp01"
    vm_size    = "Standard_D2ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  dns_prefix = "aksdns"
  location            = var.location
  resource_group_name = module.koo-rg.name
  subnet_id           = module.subnet_aks.id
  outbound_type       = "loadBalancer"
  private_cluster_enabled = false
  user_node_pool = {
    name       = "usernp01"
    vm_size    = "Standard_D4ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  # depends_on = [ 
  #   module.nat_gateway 
  # ]
  
}

module "containerregistry" {
  source = "../../modules/containerregistry"

  location            = var.location
  name                = "koocr100"
  resource_group_name = module.koo-rg.name
  sku                 = "Standard"
  admin_enabled       = true
  public_network_access_enabled = true
}