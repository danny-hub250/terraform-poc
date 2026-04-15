# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Terraform 명령어

각 환경 디렉토리에서 실행:

```bash
terraform init       # 새 모듈 추가 후 반드시 실행
terraform plan       # 변경사항 미리 확인
terraform apply      # 배포
terraform destroy    # 리소스 삭제
```

## 전체 구조

멀티 클라우드(Azure / AWS) Terraform 모노레포. 각 클라우드는 동일한 패턴을 따른다.

```
{Cloud}/
├── bootstrap/        # 원격 state 저장소 초기화 (최초 1회)
├── environments/     # 실제 배포 환경 (dev, prd 등)
└── modules/          # 재사용 가능한 모듈
```

## State 백엔드

- **Azure**: Azure Blob Storage (`kootfstate001` 스토리지 계정, `tfstate` 컨테이너)
  - bootstrap: `Azure/bootstrap/terraform-state/` — local state로 실행
  - 환경별 key: `beingax-dev.terraform.tfstate` 등
- **AWS**: S3 (`platform-tfstate-koo`) + DynamoDB 락 (`platform-tfstate-lock`)
  - 환경별 key: `dev/terraform.tfstate` 등

bootstrap은 원격 backend 설정 없이 local state로 운영한다. 환경 디렉토리에서 `terraform init` 시 원격 state가 자동 연결된다.

## Azure 환경 구조

| 환경 | 설명 |
|------|------|
| `test` | 개인 테스트 (bonahkoo-rg, 10.20.0.0/16) |
| `BeingAX-DEV` | BeingAX 개발 환경 (10.10.0.0/16, private AKS, NAT GW) |
| `BeingAX-PRD` | BeingAX 운영 환경 |
| `BeingAX-SKPC-DEV` | SKPC 개발 환경 |
| `BeingAX-SKPC-PRD` | SKPC 운영 환경 |

환경마다 `backend.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, `providers.tf`, `versions.tf` 6개 파일로 구성.

## Azure 모듈 목록

| 모듈 | 설명 |
|------|------|
| `resourcegroup` | 리소스 그룹 |
| `virtualnetwork` | VNet |
| `subnet` | 서브넷 |
| `natgateway` | NAT Gateway + subnet 연결 |
| `networksecuritygroup` | NSG |
| `routetable` | Route Table |
| `kubernetes` | AKS (system/user node pool 분리, OIDC/Workload Identity 활성화) |
| `containerregistry` | ACR |
| `linux-vm` | Ubuntu 22.04 VM |
| `windows-vm` | Windows Server VM |
| `privatednszone` | Private DNS Zone |
| `privatednszonelink` | DNS Zone ↔ VNet 연결 |
| `privateendpoint` | Private Endpoint |
| `aisearch` | Azure AI Search |
| `openai` | Azure OpenAI |
| `foundry` | Azure AI Foundry |

Private Endpoint 패턴: 서비스 모듈 → `privatednszone` → `privatednszonelink` → `privateendpoint` 순으로 연결.

## AKS 설계 특이사항

- network plugin: `azure` (overlay 모드)
- system node pool은 `only_critical_addons_enabled = true` — 워크로드는 반드시 user node pool에 배포
- outbound: DEV/PRD는 `userAssignedNATGateway`, test는 `loadBalancer`
- private cluster 여부는 환경마다 다름 (`private_cluster_enabled`)

## AWS 구조

- `bootstrap/`: S3 + DynamoDB로 state 백엔드 구성, region: `ap-northeast-2`
- `modules/vpc`: public/private 서브넷, IGW, single NAT GW, EKS 대비 subnet 태그 포함
- `modules/eks`: 미구현
- `environments/dev`: VPC 모듈만 구성됨
- provider: `hashicorp/aws v6.37`, `>= terraform 1.6.0`

## 버전 고정

- Azure provider: `azurerm 4.63.0`
- AWS provider: `aws 6.37`
- Terraform: `>= 1.6`
