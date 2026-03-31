variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type = string
  default = null
}

variable "subnet_id" {
  type = string
}

variable "node_resource_group" {
  type = string
  default = null
}

variable "system_node_pool" {
  type = object({
    name       = string
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
  })
}

variable "user_node_pool" {
  type = object({
    name       = string
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
  })
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "acr_id" {
  type    = string
  default = null
}
variable "private_cluster_enabled" {
  type = bool
  default = false
  
}
variable "tags" {
  type = map(string)
  default = {}
}

variable "outbound_type" {
  description = "loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway and none. Defaults to loadBalancer"
  type = string
}