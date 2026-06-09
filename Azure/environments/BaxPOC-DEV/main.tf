module "app-rg" {
  source = "../../modules/resourcegroup"
  name                = "bax-poc-dev-app-rg"
  location            = var.location
  tags                = var.tags
}

module "network-rg" {
  source = "../../modules/resourcegroup"
  name                = "bax-poc-dev-network-rg"
  location            = var.location
  tags                = var.tags
}

module "ai-rg" {
  source = "../../modules/resourcegroup"
  name                = "bax-poc-dev-ai-rg"
  location            = var.location
  tags                = var.tags
}


module "vnet" {
  source = "../../modules/virtualnetwork"
  name                = "bax-poc-dev-vnet"
  location            = var.location
  resource_group_name = module.network-rg.name
  address_space       = ["10.130.0.0/24"]
  tags                = var.tags
}

module "subnet_mgmt" {
  source = "../../modules/subnet"
  name                = "bax-poc-dev-mgmt-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.130.0.0/27"]
}

module "subnet_private_endpoint" {
  source = "../../modules/subnet"
  name                = "bax-poc-dev-pe-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.130.0.32/27"]
}

module "subnet_db" {
  source = "../../modules/subnet"
  name                = "bax-poc-dev-db-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.130.0.64/27"]
}

module "subnet_aks" {
  source = "../../modules/subnet"
  name                = "bax-poc-dev-aks-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.130.0.128/25"]
}

module "linux-vm" {
  source = "../../modules/linux-vm"
  name                 = "bax-poc-d-vm"
  resource_group_name  = module.app-rg.name
  location             = var.location
  subnet_id            = module.subnet_mgmt.id
  size                 = "Standard_D4s_v5"
  admin_username       = "azureuser"
  admin_password       = var.vm_admin_password
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 30
  enable_public_ip     = true
  custom_data          = base64encode(file("${path.module}/../../scripts/vm-init.sh"))
  tags                 = var.tags
}

module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name = "bax-poc-dev-aks"

  system_node_pool = {
    name       = "sysnp01"
    vm_size    = "Standard_D2s_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  dns_prefix = "aksdns"
  location            = var.location
  resource_group_name = module.app-rg.name
  subnet_id           = module.subnet_aks.id
  outbound_type       = "loadBalancer"
  private_cluster_enabled = false
  user_node_pool = {
    name       = "usernp01"
    vm_size    = "Standard_D4s_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  tags = var.tags

}

module "containerregistry" {
  source = "../../modules/containerregistry"

  location            = var.location
  name                = "baxpocdcr"
  resource_group_name = module.app-rg.name
  sku                 = "Standard"
  admin_enabled       = true
  public_network_access_enabled = true
  tags = var.tags
}

module "openai_dns" {
  source = "../../modules/privatednszone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.network-rg.name
  tags = var.tags
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
  tags = var.tags
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
  tags = var.tags
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

  name                = "bax-poc-dev-msf"
  location            = "EastUS2"
  resource_group_name = module.ai-rg.name
  tags = var.tags

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
  tags = var.tags
}

# PostgreSQL Flexible Server
module "postgresql" {
  source = "../../modules/postgresql"

  name                   = "bax-poc-dev-psql"
  location               = var.location
  resource_group_name    = module.app-rg.name
  administrator_login    = "psqladmin"
  administrator_password = var.db_admin_password
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  pg_version             = "18"
  tags                   = var.tags
}

module "postgresql_dns" {
  source = "../../modules/privatednszone"

  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = module.network-rg.name
  tags = var.tags
}

module "postgresql_dns_link" {
  source = "../../modules/privatednszonelink"

  name                = "psql-dns-link"
  resource_group_name = module.network-rg.name
  dns_zone_name       = module.postgresql_dns.name
  vnet_id             = module.vnet.id
}

module "postgresql_pe" {
  source = "../../modules/privateendpoint"

  name                = "${module.postgresql.name}-pe"
  location            = var.location
  resource_group_name = module.app-rg.name
  subnet_id           = module.subnet_db.id
  resource_id         = module.postgresql.id
  subresource_names   = ["postgresqlServer"]

  private_dns_zone_ids = [
    module.postgresql_dns.id
  ]
  tags = var.tags
}
