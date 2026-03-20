variable "name" {}
variable "resource_group_name" {}
variable "location" {}

variable "sku" {
  default = "standard"
}

variable "replica_count" {
  default = 1
}

variable "partition_count" {
  default = 1
}

variable "public_network_access_enabled" {
  default = true
}

variable "tags" {
  type = map(string)
  default = {}
}