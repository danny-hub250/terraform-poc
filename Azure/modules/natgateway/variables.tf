variable "name" {
  description = "NAT Gateway name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate"
  type        = string
  #default     = []
}

variable "create_public_ip" {
  description = "Whether to create public IP"
  type        = bool
  default     = true
}

variable "public_ip_prefix_id" {
  description = "Public IP Prefix ID (optional)"
  type        = string
  default     = null
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout"
  type        = number
  default     = 4
}

variable "zones" {
  description = "Availability zones"
  type        = list(string)
  default     = null
}

variable "tags" {
  type = map(string)
  default = {}
}