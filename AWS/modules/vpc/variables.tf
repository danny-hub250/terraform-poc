variable "name" {
  type        = string
  description = "VPC name"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}