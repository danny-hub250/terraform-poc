# VM 유틸리티 오프라인 설치 가이드

> 인터넷이 차단된 내부망 환경에서 Linux VM(Jumpbox)에 운영 도구를 설치하는 절차

---

## 1. 배경 및 구성 차이

| 구분 | 인터넷 환경 | 내부망(오프라인) 환경 |
|---|---|---|
| 설치 스크립트 | `vm-init.sh` | `vm-init-offline.sh` |
| Azure CLI | `aka.ms` URL에서 직접 설치 | 사전 다운로드된 `.deb` 사용 |
| kubectl / helm / kubelogin | GitHub/k8s.io에서 직접 다운로드 | 사전 다운로드된 바이너리 사용 |
| 시스템 패키지 | 공인 apt 미러 | **내부 apt 미러** 필요 |

---

## 2. 사전 준비 파일 목록

`Azure/scripts/offline/` 디렉터리에 아래 파일이 포함되어 있다.

| 파일 | 버전 | 크기 | 비고 |
|---|---|---|---|
| `kubectl` | v1.36.1 | ~57 MB | Linux amd64 바이너리 |
| `helm-v4.2.0-linux-amd64.tar.gz` | v4.2.0 | ~19 MB | Linux amd64 tarball |
| `kubelogin-linux-amd64.zip` | v0.2.18 | ~6 MB | Linux amd64 zip |
| `azure-cli_2.61.0-1~noble_amd64.deb` | 2.61.0 | ~54 MB | Ubuntu 24.04 (noble) deb |
| `vm-init-offline.sh` | - | - | 오프라인 설치 스크립트 |

> 📁 저장소 경로: `Azure/scripts/offline/`

---

## 3. VM으로 파일 전송

### 방법 A: scp (권장)

```bash
# 로컬 PC → VM으로 전송
scp -r Azure/scripts/offline/ azureuser@<VM Public IP>:/home/azureuser/

# 예시
scp -r Azure/scripts/offline/ azureuser@20.194.21.140:/home/azureuser/
```

### 방법 B: FTP

```
FTP 서버 주소: <VM Public IP>
계정: azureuser
비밀번호: <vm_admin_password>
업로드 경로: /home/azureuser/offline/
```

전송 대상 파일 (총 약 136 MB):

```
offline/
├── kubectl
├── helm-v4.2.0-linux-amd64.tar.gz
├── kubelogin-linux-amd64.zip
├── azure-cli_2.61.0-1~noble_amd64.deb
└── vm-init-offline.sh
```

---

## 4. VM에서 설치 실행

```bash
# 1. VM SSH 접속
ssh azureuser@<VM Public IP>

# 2. 스크립트 실행 권한 부여
chmod +x ~/offline/vm-init-offline.sh

# 3. 설치 실행
sudo bash ~/offline/vm-init-offline.sh

# 4. 설치 로그 확인
tail -f /var/log/vm-init.log
```

---

## 5. 시스템 패키지 처리 (내부 apt 미러)

`vm-init-offline.sh`의 `apt-get install` 구문은 내부 apt 미러 설정이 필요하다.

```
apt-get install -y curl wget git unzip jq net-tools dnsutils postgresql-client
```

### 옵션 1: 내부 apt 미러 사용

VM의 `/etc/apt/sources.list`를 내부 미러 주소로 교체:

```bash
# 예시 (내부 미러 주소로 변경 필요)
echo "deb http://<내부미러IP>/ubuntu noble main restricted universe" \
  > /etc/apt/sources.list
apt-get update -y
```

### 옵션 2: apt 패키지 사전 다운로드 (인터넷 환경 PC에서 실행)

```bash
# 인터넷 연결된 Ubuntu 24.04 머신에서 실행
mkdir -p ~/apt-packages
apt-get download \
  curl wget git unzip jq net-tools dnsutils postgresql-client \
  libicu74
# 의존성 포함 다운로드
apt-rdepends curl wget git unzip jq net-tools dnsutils postgresql-client \
  | grep -v "^ " | xargs apt-get download
```

다운로드한 `.deb` 파일들을 VM에 전송 후 설치:

```bash
# VM에서 실행
cd ~/apt-packages
dpkg -i *.deb
```

### 옵션 3: 해당 패키지가 이미 설치된 이미지 사용

Ubuntu 24.04 기본 이미지에는 `curl`, `wget`, `git`이 이미 설치되어 있는 경우가 많다.  
설치 여부를 먼저 확인 후 미설치 패키지만 처리한다:

```bash
dpkg -l curl wget git unzip jq net-tools dnsutils postgresql-client 2>&1 | grep -E "^ii|^un"
```

---

## 6. 설치 완료 확인

```bash
az version
kubectl version --client
helm version
kubelogin --version

# alias 적용
source ~/.bashrc
k version --client
```

---

## 7. 파일 버전 업데이트 방법

설치 파일이 오래된 경우, 인터넷 연결 PC에서 아래 스크립트로 최신 버전을 다시 다운로드한다.

```powershell
# Windows PowerShell에서 실행

$outDir = "Azure\scripts\offline"

# kubectl 최신 버전
$kubectlVer = (Invoke-WebRequest "https://dl.k8s.io/release/stable.txt" -UseBasicParsing).Content.Trim()
Invoke-WebRequest "https://dl.k8s.io/release/$kubectlVer/bin/linux/amd64/kubectl" `
  -OutFile "$outDir\kubectl" -UseBasicParsing

# helm 최신 버전
$helmVer = ((Invoke-WebRequest "https://github.com/helm/helm/releases/latest" -MaximumRedirection 5 -UseBasicParsing).BaseResponse.ResponseUri.AbsoluteUri -split "/")[-1]
Invoke-WebRequest "https://get.helm.sh/helm-$helmVer-linux-amd64.tar.gz" `
  -OutFile "$outDir\helm-$helmVer-linux-amd64.tar.gz" -UseBasicParsing

# kubelogin 최신 버전
$kubeloginVer = ((Invoke-WebRequest "https://github.com/Azure/kubelogin/releases/latest" -MaximumRedirection 5 -UseBasicParsing).BaseResponse.ResponseUri.AbsoluteUri -split "/")[-1]
Invoke-WebRequest "https://github.com/Azure/kubelogin/releases/download/$kubeloginVer/kubelogin-linux-amd64.zip" `
  -OutFile "$outDir\kubelogin-linux-amd64.zip" -UseBasicParsing

# azure-cli 최신 버전 (packages.microsoft.com에서 확인 후 URL 직접 수정)
# https://packages.microsoft.com/repos/azure-cli/pool/main/a/azure-cli/
```

---

## 8. 주의사항

- `azure-cli .deb`는 Ubuntu 버전별로 별도 패키지가 존재함 (`noble` = Ubuntu 24.04)  
  다른 Ubuntu 버전 사용 시 파일명의 `noble`을 해당 코드명으로 교체
- `kubectl` 버전은 AKS 클러스터 버전과 ±1 마이너 버전 범위를 권장
- `kubelogin`은 AKS AAD 통합 인증에 필요하며, kubectl과 독립적으로 업데이트됨
