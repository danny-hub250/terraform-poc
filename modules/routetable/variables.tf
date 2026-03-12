variable "route_table_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "routes" {
  type = map(object({
    address_prefix = string
    next_hop_type  = string
    next_hop_ip    = optional(string)
  }))
}