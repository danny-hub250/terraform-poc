# terraform-poc — Azure 인프라 Terraform 모듈 라이브러리

여러 PoC 프로젝트(AuditAX, BAX-POC)가 공유하는 재사용 Azure Terraform 모듈 모음과,
그 모듈들을 조합해 만든 환경별 배포 코드입니다.

## 디렉터리 구조

```
Azure/
├── bootstrap/
│   └── auditax-dev-tf-state/   # AuditAX-DEV용 원격 상태(state) 저장소 프로비저닝 코드
├── environments/
│   ├── AuditAX-DEV/            # Compliance(감사) 프로젝트 개발 환경
│   ├── BaxPOC-DEV/             # BeingAX AI Agent PoC 개발 환경
│   └── baxpoc-prd/             # BeingAX AI Agent PoC "운영형" 환경(R&D)
├── modules/                    # 18개 재사용 모듈
└── scripts/
    ├── vm-init.sh              # 인터넷 연결 환경용 Jumpbox VM 초기화 스크립트
    ├── vm-init-offline.sh      # 내부망(오프라인) 환경용 초기화 스크립트
    ├── offline/                # 오프라인 설치용 바이너리(az cli deb, kubectl, helm, kubelogin)
    ├── employee-app/           # AKS 배포용 샘플 앱 (Flask + PostgreSQL + Foundry 호출)
    └── hello-world/             # AKS 배포 확인용 최소 nginx 샘플

docs/
├── BAX-POC_작업기록_20260608.md(.pdf)   # BaxPOC-DEV 구축 작업 기록
├── vm-init-offline-guide.md              # 오프라인 VM 초기화 가이드
└── generate_report.py                    # 위 작업기록 md → pdf 변환 스크립트
```

## 모듈 레퍼런스

| 모듈 | 리소스 | 용도 |
|---|---|---|
| `resourcegroup` | `azurerm_resource_group` | |
| `virtualnetwork` | `azurerm_virtual_network` | |
| `subnet` | `azurerm_subnet` | |
| `networksecuritygroup` | `azurerm_network_security_group` + `azurerm_network_security_rule` + subnet 연결 | |
| `routetable` | `azurerm_route_table` + `azurerm_route` + subnet 연결 | |
| `natgateway` | `azurerm_nat_gateway` (+ Public IP/Prefix 연결) | |
| `privatednszone` / `privatednszonelink` | `azurerm_private_dns_zone` (+ vnet link) | |
| `privateendpoint` | `azurerm_private_endpoint` | Private DNS Zone Group 포함 |
| `linux-vm` | `azurerm_linux_virtual_machine` + NIC + NSG + (옵션)Public IP/데이터 디스크 | Jumpbox/관리용 VM |
| `windows-vm` | `azurerm_windows_virtual_machine` + NIC | |
| `kubernetes` | `azurerm_kubernetes_cluster` (+ 추가 node pool) | system/user 노드풀 분리 구조 |
| `containerregistry` | `azurerm_container_registry` | AKS용 이미지 레지스트리 |
| `foundry` | `azurerm_cognitive_account`(kind=AIServices) + `azurerm_cognitive_deployment` | Azure AI Foundry |
| `openai` | `azurerm_cognitive_account` | (foundry와 별도로 순수 OpenAI 계정이 필요할 때) |
| `aisearch` | `azurerm_search_service` | |
| `postgresql` | `azurerm_postgresql_flexible_server` | |

모든 모듈은 `environments/<env>/main.tf`가 조합해서 사용하는 얇은 wrapper입니다. 리소스 자체의
설정값(SKU, 크기 등)은 대부분 모듈 호출부(`main.tf`)에서 결정합니다.

## 환경 (environments/)

| 환경 | 프로젝트 | 리전 | 비고 |
|---|---|---|---|
| `AuditAX-DEV` | Compliance 감사 플랫폼 | koreacentral (Foundry만 EastUS2) | AKS + Container Registry + PostgreSQL + Foundry, **원격 상태 백엔드 사용** |
| `BaxPOC-DEV` | BeingAX AI Agent PoC | koreacentral (Foundry만 EastUS2) | AuditAX-DEV와 거의 동일 구조, 로컬 상태 |
| `baxpoc-prd` | BeingAX AI Agent PoC "R&D 운영" | koreacentral (Foundry만 EastUS2) | BaxPOC-DEV + Microsoft Defender for Servers(`security-center.tf`), 로컬 상태 |

세 환경 모두 `resourcegroup(app/network/ai 3분리) → vnet/subnet(mgmt/pe/db/aks) → linux-vm(jumpbox) →
kubernetes/containerregistry → foundry(+private endpoint) → postgresql(+private endpoint)` 구조를 그대로
반복하는 패턴입니다. 신규 환경을 추가할 때도 이 패턴을 복사해서 리소스 이름/CIDR만 바꾸면 됩니다.

### Foundry 리전이 다른 이유

세 환경 전부 `foundry` 모듈 호출부에서 `location = "EastUS2"`로 고정되어 있고, 나머지 리소스는
`var.location`(koreacentral)을 씁니다. AI Foundry에서 쓰려는 모델이 koreacentral에서 아직 제공되지
않아 리전을 분리한 것으로 보입니다 — 새 환경을 만들 때도 동일하게 유지하거나, 모델 가용 리전이
바뀌었는지 먼저 확인하세요.

## 사용법

### 1. 사전 준비

- Terraform >= 1.6, Azure CLI (`az login` 후 대상 구독 `az account set --subscription <id>`)
- `environments/<env>/terraform.tfvars` (location/tags는 이미 채워져 있음, 필요 시 수정)
- `BaxPOC-DEV`, `baxpoc-prd`, `AuditAX-DEV` 전부 VM/DB 비밀번호를 **환경변수로 주입**해야 합니다
  (main.tf에 하드코딩되어 있던 걸 `sensitive` 변수로 분리함 — 아래 "알려진 이슈" 참고):

```powershell
$env:TF_VAR_vm_admin_password = "..."
$env:TF_VAR_db_admin_password = "..."
```

### 2. (AuditAX-DEV만) 원격 상태 백엔드 부트스트랩

`AuditAX-DEV`는 `backend.tf`로 Azure Storage 원격 백엔드를 쓰기 때문에, 최초 1회
`Azure/bootstrap/auditax-dev-tf-state`를 먼저 배포해서 상태 저장용 Storage Account를 만들어야 합니다.
`BaxPOC-DEV`/`baxpoc-prd`는 별도 backend.tf가 없어 로컬 상태(`terraform.tfstate`, git에는 안 올라감)를
사용합니다 — 협업 시 원격 백엔드로 전환하는 걸 권장합니다.

```powershell
cd Azure/bootstrap/auditax-dev-tf-state
terraform init
terraform apply
```

### 3. 배포

```powershell
cd Azure/environments/<env>   # AuditAX-DEV / BaxPOC-DEV / baxpoc-prd
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

### 4. Jumpbox VM 초기화

`linux-vm` 모듈로 만들어진 VM은 `Azure/scripts/vm-init.sh`(인터넷 가능 환경) 또는
`vm-init-offline.sh`(내부망, `docs/vm-init-offline-guide.md` 참고)를 이용해 Azure CLI, Docker, kubectl,
Helm, kubelogin, k9s 등 운영 도구를 설치하고 데이터 디스크(LUN 10, 있는 경우)를 `/data`에 자동
마운트합니다. VM에 직접 올려서 실행하거나 `custom_data`로 연결해서 최초 부팅 시 자동 실행되도록 구성할
수 있습니다.

### 5. AKS 배포 확인용 샘플 앱

- `scripts/hello-world` — 최소 nginx 이미지, AKS/ACR 연동이 정상인지 빠르게 확인용
- `scripts/employee-app` — Flask 앱. PostgreSQL(`Employee` 테이블 조회)과 Foundry(`FOUNDRY_ENDPOINT`/
  `FOUNDRY_API_KEY`/`FOUNDRY_DEPLOYMENT` 환경변수)를 함께 호출하는 통합 테스트용 샘플

두 앱 모두 `containerregistry` 모듈로 만든 ACR에 빌드/푸시한 뒤 AKS에 배포하는 흐름을 검증하는 용도입니다.

### 6. 삭제

```powershell
terraform plan -destroy -out=tfdestroyplan
terraform apply "tfdestroyplan"
```

> ⚠️ `baxpoc-prd`의 `security-center.tf`(`azurerm_security_center_subscription_pricing`)는
> **구독 전체 단위** 설정이라, 이 환경만 destroy해도 다른 환경(AuditAX-DEV 등)에 적용된 Defender for
> Servers 설정은 그대로 남습니다. 자세한 내용은 파일 내 주석 참고.

## 알려진 이슈

- **[조치 완료]** `AuditAX-DEV/main.tf`에 VM/PostgreSQL 관리자 비밀번호(`Auditax12#$`)가 평문으로
  하드코딩되어 있던 것을 `BaxPOC-DEV`/`baxpoc-prd`와 동일하게 `var.vm_admin_password` /
  `var.db_admin_password`(sensitive 변수)로 분리했습니다. **다만 git history에는 과거 커밋에 평문 그대로
  남아있으므로, 이 비밀번호를 실제로 쓰고 있던 리소스가 있다면 반드시 새 비밀번호로 교체(rotate)하세요.**
- `BaxPOC-DEV`, `baxpoc-prd`는 원격 상태 백엔드가 없어 상태 파일이 로컬에만 존재합니다. 여러 명이
  같이 작업하려면 `AuditAX-DEV`처럼 Azure Storage 백엔드로 전환을 권장합니다.
- `provider "azurerm"`에 `subscription_id`가 명시되어 있지 않아, 배포 시 `az login`/`az account set`으로
  선택된 구독을 그대로 사용합니다. 잘못된 구독에 배포되지 않도록 `terraform plan` 전에 `az account show`로
  현재 구독을 꼭 확인하세요.
