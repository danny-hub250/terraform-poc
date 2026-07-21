variable "name" {}
variable "resource_group_name" {}
variable "location" {}


variable "tags" {
  type = map(string)
  default = {}
}

variable "deployment_name" {
  type    = string
  default = "gpt-5-mini"
}

variable "model_name" {
  type    = string
  default = "gpt-5-mini"
}

variable "model_version" {
  type    = string
  default = "2025-08-07"
}

variable "deployment_sku_name" {
  type    = string
  default = "GlobalStandard"
}

variable "deployment_capacity" {
  type    = number
  default = 10
}