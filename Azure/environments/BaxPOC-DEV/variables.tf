variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vm_admin_password" {
  type      = string
  sensitive = true
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}
