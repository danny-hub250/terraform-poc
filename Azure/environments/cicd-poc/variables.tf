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

variable "github_owner" {
  description = "GitHub 계정 이름"
  type        = string
  default     = "danny-hub250"
}

variable "github_owner_id" {
  description = "GitHub 계정(danny-hub250)의 숫자 ID. 이 계정의 저장소들은 OIDC subject claim이 owner@id/repo@id 형식(GitHub 기본값)으로 발급되므로 federated credential subject 구성에 필요"
  type        = string
  default     = "75007531"
}

variable "github_branch" {
  description = "GitHub Actions OIDC federated credential이 신뢰할 브랜치 (모든 앱 공통)"
  type        = string
  default     = "main"
}

variable "github_actions_apps" {
  description = <<-EOT
    cicd-poc-gha-uami를 신뢰하는(=ACR push 가능한) GitHub 저장소 목록.
    저장소를 하나 추가할 때마다 여기에 항목을 추가하면 federated credential이 자동 생성된다.
    repo_id는 `gh api repos/<owner>/<repo> --jq .id`로 조회 (저장소를 삭제 후 재생성하면 값이 바뀜 -
    바뀐 경우 GitHub Actions 실행 로그의 AADSTS700213 에러 메시지에 찍히는 실제 subject로 갱신할 것).
  EOT
  type = map(object({
    repo_id = string
  }))
  default = {
    "cicd-poc" = {
      repo_id = "1344676653"
    }
    "ai-cloud-advisor" = {
      repo_id = "1278624361"
    }
  }
}
