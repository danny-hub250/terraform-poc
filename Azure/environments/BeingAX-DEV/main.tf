

module "ai-rg" {
  source = "../../modules/resourcegroup"
  name                = "bax-ai-dev-rg"
  location            = var.location
  tags                = var.tags
}

module "app-rg" {
  source = "../../modules/resourcegroup"
  name                = "bax-app-dev-rg"
  location            = var.location
  tags                = var.tags
}

module "network-rg" {
  source = "../../modules/resourcegroup"
  name                = "bax-network-dev-rg"
  location            = var.location
  tags                = var.tags
}

module "vnet" {
  source = "../../modules/virtualnetwork"
  name                = "bax-vnet"
  location            = var.location
  resource_group_name = module.network-rg.name
  address_space       = ["10.10.0.0/16"]
  tags                = var.tags
}

module "subnet_aks" {
  source = "../../modules/subnet"
  name                = "bax-aks-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.10.1.0/24"]
}

module "subnet_private_endpoint" {
  source = "../../modules/subnet"
  name                = "bax-pe-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.10.2.0/24"]
}
module "nat_gateway" {
  source = "../../modules/natgateway"
  name                = "bax-natgw"
  location            = var.location
  resource_group_name = module.network-rg.name
  subnet_ids          = module.subnet_aks.id
  tags                = var.tags
}

module "linux-vm" {
  source = "../../modules/linux-vm"
  name                = "bax-vm"
  resource_group_name = module.app-rg.name
  location            = var.location
  subnet_id           = module.subnet_aks.id
  size                = "Standard_D2ds_v5"
  admin_password      = "Azure2023!!!"
  storage_account_type = "Standard_LRS"
  disk_size_gb = 30
  tags = var.tags
}


module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name = "bax-aks"
  
  system_node_pool = {
    name       = "sysnp01"
    vm_size    = "Standard_D2ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  dns_prefix = "aksdns"
  location            = var.location
  resource_group_name = module.app-rg.name
  subnet_id           = module.subnet_aks.id
  outbound_type       = "userAssignedNATGateway"
  private_cluster_enabled = true
  user_node_pool = {
    name       = "usernp01"
    vm_size    = "Standard_D4ds_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  depends_on = [ 
    module.nat_gateway 
  ]
  
}

module "containerregistry" {
  source = "../../modules/containerregistry"

  location            = var.location
  name                = "baxdevcr1"
  resource_group_name = module.app-rg.name
  sku                 = "Premium"
  admin_enabled       = true
  public_network_access_enabled = true
}
module "containerregistry_dns" {
  source = "../../modules/privatednszone"

  name                = "privatelink.azurecr.io"
  resource_group_name = module.network-rg.name
}

module "containerregistry_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "baxdevcr1-dns-link"
  resource_group_name = module.network-rg.name
  dns_zone_name       = module.containerregistry_dns.name
  vnet_id             = module.vnet.id
}

module "containerregistry_pe" {
  source = "../../modules/privateendpoint"

  name                = "${module.containerregistry.name}-pe"
  location            = var.location
  resource_group_name = module.app-rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.containerregistry.id
  subresource_names   = ["registry"]

  private_dns_zone_ids = [
    module.containerregistry_dns.id
  ]
}

module "aisearch" {
  source = "../../modules/aisearch"
  name                = "bax-dev-srch01"
  resource_group_name = module.ai-rg.name
  location            = var.location
  sku                 = "standard"
}
module "aisearch_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.search.windows.net"
  resource_group_name = module.network-rg.name
}

module "aisearch_dns_link" {
  source = "../../modules/privatednszonelink"
  name                = "aisearch-dns-link"
  resource_group_name = module.network-rg.name
  dns_zone_name       = module.aisearch_dns.name
  vnet_id             = module.vnet.id
}

module "aisearch_pe" {
  source = "../../modules/privateendpoint"

  name                = "${module.aisearch.name}-pe"
  location            = var.location
  resource_group_name = module.ai-rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.aisearch.id
  subresource_names   = ["searchService"]

  private_dns_zone_ids = [
    module.aisearch_dns.id
  ]
}

module "openai_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.network-rg.name
}

module "openai_dns_link" {
  source = "../../modules/privatednszonelink"
  name                = "openai-dns-link"
  resource_group_name = module.network-rg.name
  dns_zone_name       = module.openai_dns.name
  vnet_id             = module.vnet.id
}

module "cog_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = module.network-rg.name
}

module "cog_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "cog-dns-link"
  resource_group_name = module.network-rg.name
  dns_zone_name       = module.cog_dns.name
  vnet_id             = module.vnet.id
}

module "serviceai_dns" {
  source = "../../modules/privatednszone"

  name                = "privatelink.services.ai.azure.com"
  resource_group_name = module.network-rg.name
}

module "serviceai_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "serviceai-dns-link"
  resource_group_name = module.network-rg.name
  dns_zone_name       = module.serviceai_dns.name
  vnet_id             = module.vnet.id
}



module "foundry" {
  source = "../../modules/foundry"

  name                = "bax-msf"
  location            = "EastUS2"
  resource_group_name = module.ai-rg.name
  
}

module "foundry_pe" {
  source = "../../modules/privateendpoint"

  name                = "${module.foundry.name}-pe"
  location            = var.location
  resource_group_name = module.ai-rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.foundry.id
  subresource_names   = ["account"]

  private_dns_zone_ids = [
    module.openai_dns.id,
    module.cog_dns.id,
    module.serviceai_dns.id
  ]
}