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

variable "github_repo" {
  description = "CI/CD 소스가 있는 GitHub 레포 (owner/repo). GitHub Actions OIDC federated credential의 subject를 구성하는 데 사용"
  type        = string
  default     = "danny-hub250/cicd-poc"
}

variable "github_branch" {
  description = "GitHub Actions OIDC federated credential이 신뢰할 브랜치"
  type        = string
  default     = "main"
}
