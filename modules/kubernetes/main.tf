resource "azurerm_kubernetes_cluster" "aks" {

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version  = var.kubernetes_version

  node_resource_group = var.node_resource_group

  default_node_pool {

    name                = var.system_node_pool.name
    vm_size             = var.system_node_pool.vm_size
    node_count          = var.system_node_pool.node_count

    vnet_subnet_id      = var.subnet_id

    min_count           = var.system_node_pool.min_count
    max_count           = var.system_node_pool.max_count

    type = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {

    network_plugin = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku = "standard"

    outbound_type = "loadBalancer"

  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  role_based_access_control_enabled = true

  dynamic "oms_agent" {

    for_each = var.log_analytics_workspace_id == null ? [] : [1]

    content {

      log_analytics_workspace_id = var.log_analytics_workspace_id

    }

  }

  tags = var.tags
}