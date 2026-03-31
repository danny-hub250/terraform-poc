variable "name" {
  description = "ACR name (globally unique)"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  description = "Basic / Standard / Premium"
  type        = string
}

variable "admin_enabled" {
  type    = bool
}

variable "public_network_access_enabled" {
  type    = bool
}

variable "tags" {
  type    = map(string)
  default = {}
}