variable "name" {
  type = string
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
  type      = string
}
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "disk_size_gb" {
  description = "The Size of the Internal OS Disk in GB"
  type        = number
}

variable "enable_public_ip" {
  description = "true로 설정하면 Public IP를 생성해 NIC에 부착"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
