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

# module "nat_gateway" {
#   source = "../../modules/natgateway"

#   nat_gateway_name    = "dev-nat"
#   public_ip_name      = "dev-nat-ip"
#   resource_group_name = module.rg.name
#   location            = var.location
#   subnet_id           = module.subnet.id
# }

# module "route_table" {
#   source = "../../modules/routetable"

#   route_table_name    = "dev-aks-rt"
#   location            = var.location
#   resource_group_name = module.rg.name
#   subnet_id           = module.subnet.subnet_id

#   routes = {
#     default = {
#       address_prefix = "0.0.0.0/0"
#       next_hop_type  = "VirtualAppliance"
#       next_hop_ip    = "10.0.100.4"
#     }
#   }
# }

module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name = "koo-aks"
  
  system_node_pool = {
    name       = "devnp"
    vm_size    = "Standard_D4ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  dns_prefix = "aksdns"
  location            = var.location
  resource_group_name = module.rg.name
  subnet_id           = module.subnet_aks.subnet_id
  
}