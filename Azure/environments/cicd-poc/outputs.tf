# ── 리소스 그룹 ──────────────────────────────────────────────
output "app_resource_group" {
  value = module.app-rg.name
}

output "network_resource_group" {
  value = module.network-rg.name
}

output "ai_resource_group" {
  value = module.ai-rg.name
}

# ── Jumpbox VM ───────────────────────────────────────────────
output "vm_public_ip" {
  value       = module.linux-vm.public_ip_address
  description = "SSH: ssh azureuser@<vm_public_ip>"
}

# ── AKS ──────────────────────────────────────────────────────
output "aks_cluster_name" {
  value = module.kubernetes.name
}

output "aks_node_resource_group" {
  value = module.kubernetes.node_resource_group
}

output "aks_oidc_issuer_url" {
  value = module.kubernetes.oidc_issuer_url
}

output "aks_get_credentials_command" {
  value = "az aks get-credentials --resource-group ${module.app-rg.name} --name ${module.kubernetes.name} --overwrite-existing"
}

# ── ACR ──────────────────────────────────────────────────────
output "acr_login_server" {
  value = module.containerregistry.login_server
}

output "acr_name" {
  value = module.containerregistry.name
}

# ── PostgreSQL ───────────────────────────────────────────────
output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}

output "postgresql_name" {
  value = module.postgresql.name
}

# ── Foundry ──────────────────────────────────────────────────
output "foundry_endpoint" {
  value = module.foundry.endpoint
}

output "foundry_deployment_name" {
  value = module.foundry.deployment_name
}

output "foundry_primary_access_key" {
  value     = module.foundry.primary_access_key
  sensitive = true
}

# ── GitHub Actions OIDC (secretless 로그인) ──────────────────
# 아래 3개 값을 cicd-poc GitHub 레포의 Settings > Secrets and variables > Actions 에 등록
output "github_actions_client_id" {
  value       = azurerm_user_assigned_identity.github_actions.client_id
  description = "GitHub Secrets: AZURE_CLIENT_ID"
}

output "github_actions_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "GitHub Secrets: AZURE_TENANT_ID"
}

output "github_actions_subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "GitHub Secrets: AZURE_SUBSCRIPTION_ID"
}
