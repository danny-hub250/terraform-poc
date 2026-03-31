

module "rg" {

  source = "../../modules/resourcegroup"

  name     = "koo-dev-rg"
  location = var.location

  tags = var.tags

}

module "vnet" {

  source = "../../modules/virtualnetwork"

  name                = "koo-vnet"
  location            = var.location
  resource_group_name = module.rg.name

  address_space = ["10.10.0.0/16"]

}

module "subnet_aks" {

  source = "../../modules/subnet"

  name                = "aks-subnet"
  resource_group_name = module.rg.name
  vnet_name           = module.vnet.name

  address_prefixes = ["10.10.1.0/24"]

}

module "subnet_private_endpoint" {

  source = "../../modules/subnet"

  name                = "pe-subnet"
  resource_group_name = module.rg.name
  vnet_name           = module.vnet.name

  address_prefixes = ["10.10.2.0/24"]

}
module "nat_gateway" {
  source = "../../modules/natgateway"

  name                = "koo-natgw"
  location            = var.location
  resource_group_name = module.rg.name

  subnet_ids = [
    module.subnet_aks.id
  ]

  tags = var.tags
}


module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name = "koo-aks"
  
  system_node_pool = {
    name       = "sysnp01"
    vm_size    = "Standard_D4ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  dns_prefix = "aksdns"
  location            = var.location
  resource_group_name = module.rg.name
  subnet_id           = module.subnet_aks.id
  outbound_type = "userAssignedNATGateway"
  user_node_pool = {
    name       = "usernp01"
    vm_size    = "Standard_D4ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  
}

module "containerregistry" {
  source = "../../modules/containerregistry"

  location = var.location
  name     = "kooregistry1"
  resource_group_name = module.rg.name
  sku = "Premium"
}
module "containerregistry_dns" {
  source = "../../modules/privatednszone"

  name                = "privatelink.azurecr.io"
  resource_group_name = module.rg.name
}

module "containerregistry_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "containerregistry-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.containerregistry_dns.name
  vnet_id             = module.vnet.id
}

module "containerregistry_pe" {
  source = "../../modules/privateendpoint"

  name                = "koo-containerregistry-pe"
  location            = var.location
  resource_group_name = module.rg.name

  subnet_id = module.subnet_private_endpoint.id

  resource_id = module.containerregistry.id

  subresource_names = ["registry"]

  private_dns_zone_ids = [
    module.containerregistry_dns.id
  ]
}

module "aisearch" {
  source = "../../modules/aisearch"

  name                = "koo-ai-search"
  resource_group_name = module.rg.name
  location            = var.location

  sku = "standard"
}
module "aisearch_dns" {
  source = "../../modules/privatednszone"

  name                = "privatelink.search.windows.net"
  resource_group_name = module.rg.name
}

module "aisearch_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "aisearch-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.aisearch_dns.name
  vnet_id             = module.vnet.id
}

module "aisearch_pe" {
  source = "../../modules/privateendpoint"

  name                = "koo-aisearch-pe"
  location            = var.location
  resource_group_name = module.rg.name

  subnet_id = module.subnet_private_endpoint.id

  resource_id = module.aisearch.id

  subresource_names = ["searchService"]

  private_dns_zone_ids = [
    module.aisearch_dns.id
  ]
}
module "openai" {
  source = "../../modules/openai"

  name                = "koo-openai"
  resource_group_name = module.rg.name
  location            = "EastUS2" #신규 모델이 배포되는 location은 EastUS2, SwedenCentral
  custom_subdomain_name = "koo-openai"
}

module "openai_dns" {
  source = "../../modules/privatednszone"

  name                = "privatelink.openai.azure.com"
  resource_group_name = module.rg.name
}

module "openai_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "openai-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.openai_dns.name
  vnet_id             = module.vnet.id
}

module "openai_pe" {
  source = "../../modules/privateendpoint"

  name                = "koo-openai-pe"
  location            = var.location
  resource_group_name = module.rg.name

  subnet_id = module.subnet_private_endpoint.id

  resource_id = module.openai.id

  subresource_names = ["account"]

  private_dns_zone_ids = [
    module.openai_dns.id
  ]
}

