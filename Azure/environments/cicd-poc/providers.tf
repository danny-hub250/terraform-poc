provider "azurerm" {
  features {}
}

# GitHub Actions OIDC federated credential에 필요한 tenant_id / subscription_id 조회용
data "azurerm_client_config" "current" {}
