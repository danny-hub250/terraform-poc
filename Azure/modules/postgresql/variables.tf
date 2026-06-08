variable "name" {
  type        = string
  description = "PostgreSQL Flexible Server 이름"
}

variable "location" {
  type        = string
  description = "Azure 리전"
}

variable "resource_group_name" {
  type        = string
  description = "리소스 그룹 이름"
}

variable "administrator_login" {
  type        = string
  description = "관리자 계정 이름"
}

variable "administrator_password" {
  type        = string
  sensitive   = true
  description = "관리자 계정 비밀번호"
}

variable "sku_name" {
  type        = string
  default     = "B_Standard_B1ms"
  description = "SKU (예: B_Standard_B1ms, GP_Standard_D2s_v3)"
}

variable "storage_mb" {
  type        = number
  default     = 32768
  description = "스토리지 크기 (MB 단위, 최소 32768)"
}

variable "pg_version" {
  type        = string
  default     = "16"
  description = "PostgreSQL 버전"
}

variable "backup_retention_days" {
  type        = number
  default     = 7
  description = "백업 보존 일수 (7~35)"
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  default     = false
  description = "지역 중복 백업 활성화 여부"
}

variable "tags" {
  type    = map(string)
  default = {}
}
