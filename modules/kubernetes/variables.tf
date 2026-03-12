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

variable "user_node_pools" {
  type = map(object({
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "acr_id" {
  type    = string
  default = null
}

variable "tags" {
  type = map(string)
  default = {}
}