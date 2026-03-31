variable "name" {}
variable "resource_group_name" {}
variable "location" {}


variable "tags" {
  type = map(string)
  default = {}
}