#!/bin/bash
set -euo pipefail

LOG=/var/log/vm-init.log
exec > >(tee -a "$LOG") 2>&1
echo "=== vm-init start: $(date) ==="

# ── SSH 패스워드 인증 활성화 ────────────────────────────────────
# Ubuntu 24.04 cloud image의 60-cloudimg-settings.conf가 PasswordAuthentication no를
# 설정하므로, 더 높은 우선순위 파일로 덮어씀
echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/70-azure-override.conf
systemctl restart ssh

# ── 시스템 패키지 설치 ─────────────────────────────────────────
# upgrade 제외: walinuxagent 업그레이드 시 확장 핸들러 경로가 깨지는 문제 방지
apt-get update -y
apt-get install -y curl wget git unzip jq net-tools dnsutils postgresql-client

# ── Azure CLI ─────────────────────────────────────────────────
echo ">>> Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
az version

# ── kubectl ───────────────────────────────────────────────────
echo ">>> Installing kubectl..."
KUBECTL_VERSION=$(curl -sSL https://dl.k8s.io/release/stable.txt)
curl -sSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl
kubectl version --client

# ── Helm ──────────────────────────────────────────────────────
echo ">>> Installing Helm..."
curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# ── kubelogin (AKS AAD 인증) ──────────────────────────────────
echo ">>> Installing kubelogin..."
KUBELOGIN_VERSION=$(curl -sSL https://api.github.com/repos/Azure/kubelogin/releases/latest \
  | jq -r '.tag_name')
curl -sSLO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip"
unzip -q kubelogin-linux-amd64.zip
mv bin/linux_amd64/kubelogin /usr/local/bin/kubelogin
rm -rf bin kubelogin-linux-amd64.zip
kubelogin --version

echo "=== vm-init complete: $(date) ==="
