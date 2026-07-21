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

variable "delegated_subnet_id" {
  type        = string
  description = "Microsoft.DBforPostgreSQL/flexibleServers로 위임된 서브넷 ID (VNet 통합)"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS Zone ID (이름이 *.postgres.database.azure.com 으로 끝나야 함)"
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

variable "zone" {
  type        = string
  default     = null
  description = "가용성 영역. Azure가 생성 시 자동 할당한 값과 다르게 지정하면 재생성이 발생할 수 있으므로, 기존 서버는 실제 할당된 zone 값으로 고정 권장"
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
