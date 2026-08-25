module "app-rg" {
  source = "../../modules/resourcegroup"
  name                = "cicd-poc-app-rg"
  location            = var.location
  tags                = var.tags
}

module "network-rg" {
  source = "../../modules/resourcegroup"
  name                = "cicd-poc-network-rg"
  location            = var.location
  tags                = var.tags
}

module "ai-rg" {
  source = "../../modules/resourcegroup"
  name                = "cicd-poc-ai-rg"
  location            = var.location
  tags                = var.tags
}


module "vnet" {
  source = "../../modules/virtualnetwork"
  name                = "cicd-poc-vnet"
  location            = var.location
  resource_group_name = module.network-rg.name
  address_space       = ["10.150.0.0/24"]
  tags                = var.tags
}

module "subnet_mgmt" {
  source = "../../modules/subnet"
  name                = "cicd-poc-mgmt-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.150.0.0/27"]
}

module "subnet_private_endpoint" {
  source = "../../modules/subnet"
  name                = "cicd-poc-pe-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.150.0.32/27"]
}

module "subnet_db" {
  source = "../../modules/subnet"
  name                = "cicd-poc-db-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.150.0.64/27"]

  delegation_name         = "fs"
  service_delegation_name = "Microsoft.DBforPostgreSQL/flexibleServers"
}

module "subnet_aks" {
  source = "../../modules/subnet"
  name                = "cicd-poc-aks-snet"
  resource_group_name = module.network-rg.name
  vnet_name           = module.vnet.name
  address_prefixes    = ["10.150.0.128/25"]
}

module "linux-vm" {
  source = "../../modules/linux-vm"
  name                 = "cicd-poc-vm"
  resource_group_name  = module.app-rg.name
  location             = var.location
  subnet_id            = module.subnet_mgmt.id
  size                 = "Standard_D4s_v5"
  admin_username       = "azureuser"
  admin_password       = var.vm_admin_password
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 30
  data_disk_size_gb    = 128
  enable_public_ip     = true
  tags                 = var.tags
}

module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name = "cicd-poc-aks"

  system_node_pool = {
    name       = "sysnp01"
    vm_size    = "Standard_D2s_v5"
    node_count = 1
    min_count  = null
    max_count  = null
  }
  dns_prefix          = "cicdpocdns"
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
  name                = "cicdpocacr08"
  resource_group_name = module.app-rg.name
  sku                 = "Standard"
  admin_enabled       = true
  public_network_access_enabled = true
  tags = var.tags
}

# AKS(kubelet ID) -> ACR: 노드가 이미지를 pull 할 수 있도록 AcrPull 부여
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.containerregistry.id
  role_definition_name = "AcrPull"
  principal_id         = module.kubernetes.kubelet_identity_object_id
}

# ── GitHub Actions -> Azure OIDC 로그인용 관리 ID ──────────────────────
# 시크릿(client secret)을 GitHub에 저장하지 않고, GitHub OIDC 토큰을 이 관리 ID로
# 교환해 로그인한다 (azure/login@v2 action, federated credential 방식).
resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "cicd-poc-gha-uami"
  location            = var.location
  resource_group_name = module.app-rg.name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github_actions" {
  for_each  = var.github_actions_apps
  name      = "github-actions-${each.key}-${replace(var.github_branch, "/", "-")}"
  parent_id = azurerm_user_assigned_identity.github_actions.id

  issuer = "https://token.actions.githubusercontent.com"
  # subject 형식은 저장소별로 다르다 (AADSTS700213로 실제 확인됨 - 계정 전체 기본값이 아님).
  # repo_id가 있으면 owner@owner_id/repo@repo_id 형식, 없으면 일반 owner/repo 형식.
  subject = (
    each.value.repo_id != null
    ? "repo:${var.github_owner}@${var.github_owner_id}/${each.key}@${each.value.repo_id}:ref:refs/heads/${var.github_branch}"
    : "repo:${var.github_owner}/${each.key}:ref:refs/heads/${var.github_branch}"
  )
  audience = ["api://AzureADTokenExchange"]
}

# CI가 이미지를 빌드해서 ACR에 push 할 수 있도록 AcrPush 부여 (그 이상 권한은 필요 없음.
# AKS 배포는 ArgoCD가 클러스터 내부에서 git/ACR을 직접 보고 수행)
resource "azurerm_role_assignment" "gha_acr_push" {
  scope                = module.containerregistry.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
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

  name                = "cicd-poc-msf"
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

# PostgreSQL Flexible Server - Private DNS Zone (VNet 통합용)
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

  depends_on = [module.subnet_db]
}

# PostgreSQL Flexible Server - VNet 통합 (delegated subnet, Private Endpoint 미지원)
module "postgresql" {
  source = "../../modules/postgresql"

  name                   = "cicd-poc-psql"
  location               = var.location
  resource_group_name    = module.app-rg.name
  administrator_login    = "psqladmin"
  administrator_password = var.db_admin_password
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  pg_version             = "18"
  zone                   = "1" # Azure가 생성 시 자동 할당한 실제 zone 값 (az postgres flexible-server show 로 확인)
  delegated_subnet_id    = module.subnet_db.id
  private_dns_zone_id    = module.postgresql_dns.id
  tags                   = var.tags

  depends_on = [module.postgresql_dns_link]
}
