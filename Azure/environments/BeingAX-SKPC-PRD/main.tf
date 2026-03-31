

module "rg" {
  source = "../../modules/resourcegroup"
  name     = "bax-gsm-prd-ai-rg"
  location = var.location
  tags = var.tags
}

module "vnet" {
  source = "../../modules/virtualnetwork"
  name                = "bax-gsm-prd-vnet"
  location            = var.location
  resource_group_name = module.rg.name
  address_space = ["10.100.0.0/27"]
  tags = var.tags
}


module "subnet_private_endpoint" {
  source = "../../modules/subnet"
  name                = "bax-gsm-prd-pe-snet"
  resource_group_name = module.rg.name
  vnet_name           = module.vnet.name
  address_prefixes = ["10.100.0.0/27"]
}


### Container Registry와 P.E 배포를 위한 module 집합 ###

module "containerregistry" {
  source = "../../modules/containerregistry"
  location = var.location
  name     = "baxgsmprdcr1"
  resource_group_name = module.rg.name
  sku = "Premium"
  admin_enabled = true
  public_network_access_enabled = true
  tags = var.tags
}

module "containerregistry_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.azurecr.io"
  resource_group_name = module.rg.name
  tags = var.tags
}

module "containerregistry_dns_link" {
  source = "../../modules/privatednszonelink"
  name                = "baxgsmprdcr1-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.containerregistry_dns.name
  vnet_id             = module.vnet.id
}

module "containerregistry_pe" {
  source = "../../modules/privateendpoint"
  name                = "${module.containerregistry.name}-pe"
  location            = var.location
  resource_group_name = module.rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.containerregistry.id
  subresource_names   = ["registry"]

  private_dns_zone_ids = [
    module.containerregistry_dns.id
  ]
  tags = var.tags
}

### AI Search & P.E 작업을 위한 모듈들 집합 ###

module "aisearch" {
  source = "../../modules/aisearch"
  name                = "bax-gsm-prd-srch01"
  resource_group_name = module.rg.name
  location            = var.location

  sku = "standard"
  tags = var.tags
}
module "aisearch_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.search.windows.net"
  resource_group_name = module.rg.name
  tags = var.tags
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
  name                = "${module.aisearch.name}-pe"
  location            = var.location
  resource_group_name = module.rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.aisearch.id
  subresource_names   = ["searchService"]

  private_dns_zone_ids = [
    module.aisearch_dns.id
  ]
  tags = var.tags
}

### Foundry를 위한 modules들 집합 ###

module "openai_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.rg.name
  tags = var.tags
}

module "openai_dns_link" {
  source = "../../modules/privatednszonelink"
  name                = "openai-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.openai_dns.name
  vnet_id             = module.vnet.id
}

module "cog_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = module.rg.name
  tags = var.tags
}

module "cog_dns_link" {
  source = "../../modules/privatednszonelink"
  name                = "openai-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.cog_dns.name
  vnet_id             = module.vnet.id
}

module "serviceai_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = module.rg.name
  tags = var.tags
}

module "serviceai_dns_link" {
  source = "../../modules/privatednszonelink"
  name                = "serviceai-dns-link"
  resource_group_name = module.rg.name
  dns_zone_name       = module.serviceai_dns.name
  vnet_id             = module.vnet.id
}



module "foundry" {
  source = "../../modules/Foundry"
  name                = "bax-gsm-prd-msf"
  location            = "EastUS2"
  resource_group_name = module.rg.name
  tags = var.tags
  
}

module "foundry_pe" {
  source = "../../modules/privateendpoint"

  name                = "${module.foundry.name}-pe"
  location            = var.location
  resource_group_name = module.rg.name
  subnet_id           = module.subnet_private_endpoint.id
  resource_id         = module.foundry.id
  subresource_names   = ["account"]
  
  private_dns_zone_ids = [
    module.openai_dns.id,
    module.cog_dns.id,
    module.serviceai_dns.id
  ]
  tags = var.tags
}