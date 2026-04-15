variable "name" {
  type = string
}

variable "computer_name" {
  description = "Windows computer name (max 15 characters)"
  type        = string
}

variable "subnet_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_type" {
  description = "Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  type        = string
}

variable "size" {
  description = "Standard_D2ds_v5 ...."
  type        = string
}

variable "admin_username" {
  description = "Administrator username (cannot be 'Administrator', 'Admin', 'User', 'Guest')"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "image_sku" {
  description = "Windows Server SKU. e.g. 2019-Datacenter, 2022-Datacenter, 2022-datacenter-azure-edition"
  type        = string
  default     = "2022-Datacenter"
}

variable "disk_size_gb" {
  description = "The Size of the Internal OS Disk in GB"
  type        = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
