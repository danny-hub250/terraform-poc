#!/bin/bash
# =============================================================================
# vm-init-offline.sh - 내부망(인터넷 차단) 환경용 VM 초기화 스크립트
#
# 사전 준비:
#   아래 파일들이 이 스크립트와 동일 디렉터리에 있어야 함
#   - kubectl
#   - helm-v4.2.0-linux-amd64.tar.gz
#   - kubelogin-linux-amd64.zip
#   - azure-cli_2.61.0-1~noble_amd64.deb
#
# 실행 방법:
#   sudo bash vm-init-offline.sh
# =============================================================================
set -euo pipefail

LOG=/var/log/vm-init.log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec > >(tee -a "$LOG") 2>&1
echo "=== vm-init-offline start: $(date) ==="
echo "Script directory: $SCRIPT_DIR"

# ── SSH 패스워드 인증 활성화 ────────────────────────────────────
# Ubuntu 24.04 cloud image의 60-cloudimg-settings.conf가 PasswordAuthentication no를
# 설정하므로, 더 높은 우선순위 파일로 덮어씀
echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/70-azure-override.conf
systemctl restart ssh
echo ">>> SSH password auth enabled"

# ── 시스템 패키지 설치 (내부 apt 미러 필요) ────────────────────
# upgrade 제외: walinuxagent 업그레이드 시 확장 핸들러 경로가 깨지는 문제 방지
echo ">>> Installing system packages..."
apt-get update -y
apt-get install -y curl wget git unzip jq net-tools dnsutils postgresql-client

# ── Azure CLI (로컬 .deb) ─────────────────────────────────────
echo ">>> Installing Azure CLI from local deb..."
DEB_FILE=$(ls "$SCRIPT_DIR"/azure-cli_*.deb 2>/dev/null | head -1)
if [ -z "$DEB_FILE" ]; then
  echo "ERROR: azure-cli .deb not found in $SCRIPT_DIR" >&2
  exit 1
fi
apt-get install -y libicu-dev  # 런타임 의존성
dpkg -i "$DEB_FILE" || apt-get install -f -y  # 의존성 미충족 시 자동 보완
az version
echo ">>> Azure CLI installed"

# ── kubectl (로컬 바이너리) ───────────────────────────────────
echo ">>> Installing kubectl..."
if [ ! -f "$SCRIPT_DIR/kubectl" ]; then
  echo "ERROR: kubectl binary not found in $SCRIPT_DIR" >&2
  exit 1
fi
install -o root -g root -m 0755 "$SCRIPT_DIR/kubectl" /usr/local/bin/kubectl
kubectl version --client
echo ">>> kubectl installed"

# ── Helm (로컬 tarball) ───────────────────────────────────────
echo ">>> Installing Helm..."
HELM_TAR=$(ls "$SCRIPT_DIR"/helm-*-linux-amd64.tar.gz 2>/dev/null | head -1)
if [ -z "$HELM_TAR" ]; then
  echo "ERROR: helm tarball not found in $SCRIPT_DIR" >&2
  exit 1
fi
tar -zxf "$HELM_TAR" -C /tmp linux-amd64/helm
install -o root -g root -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm
rm -rf /tmp/linux-amd64
helm version
echo ">>> Helm installed"

# ── kubelogin (로컬 zip) ──────────────────────────────────────
echo ">>> Installing kubelogin..."
if [ ! -f "$SCRIPT_DIR/kubelogin-linux-amd64.zip" ]; then
  echo "ERROR: kubelogin zip not found in $SCRIPT_DIR" >&2
  exit 1
fi
unzip -qo "$SCRIPT_DIR/kubelogin-linux-amd64.zip" -d /tmp/kubelogin
install -o root -g root -m 0755 /tmp/kubelogin/bin/linux_amd64/kubelogin /usr/local/bin/kubelogin
rm -rf /tmp/kubelogin
kubelogin --version
echo ">>> kubelogin installed"

# ── kubectl alias ─────────────────────────────────────────────
echo "alias k=kubectl" >> /home/azureuser/.bashrc
echo "alias k=kubectl" >> /root/.bashrc

echo "=== vm-init-offline complete: $(date) ==="
