variable "name" {}
variable "resource_group_name" {}
variable "location" {}

variable "public_network_access_enabled" {
  default = true
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "custom_subdomain_name" {
  description = "OpenAI custom subdomain"
}