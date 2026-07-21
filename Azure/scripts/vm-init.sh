#!/bin/bash
set -euo pipefail

LOG=/var/log/vm-init.log
exec > >(tee -a "$LOG") 2>&1
echo "=== vm-init start: $(date) ==="

# ── 데이터 디스크 마운트 ─────────────────────────────────────────
# Terraform에서 LUN 10으로 붙인 데이터 디스크(있는 경우)를 /data에 마운트.
# blkid/mkfs.ext4/mount 등은 Ubuntu 기본 이미지에 이미 포함되어 있어
# apt-get install보다 먼저 실행 가능. 디스크가 없는 환경(LUN 10 미부착)에서는 건너뜀.
# 이미 포맷/마운트되어 있으면 재실행해도 데이터를 건드리지 않음(idempotent).
DATA_DISK_LINK="/dev/disk/azure/scsi1/lun10"
MOUNT_POINT="/data"

if [ -L "$DATA_DISK_LINK" ]; then
  DATA_DISK=$(readlink -f "$DATA_DISK_LINK")
  DATA_PART="${DATA_DISK}1"

  if ! blkid "$DATA_PART" >/dev/null 2>&1; then
    echo ">>> Partitioning and formatting data disk ${DATA_DISK}..."
    echo ';' | sfdisk "$DATA_DISK"
    udevadm settle
    mkfs.ext4 -F "$DATA_PART"
  else
    echo ">>> ${DATA_PART} already has a filesystem, skipping format"
  fi

  mkdir -p "$MOUNT_POINT"

  grep -q "^${DATA_PART}[[:space:]]" /etc/fstab || \
    echo "${DATA_PART} ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab

  mountpoint -q "$MOUNT_POINT" || mount "$MOUNT_POINT"
  echo ">>> Data disk mounted at ${MOUNT_POINT}"
else
  echo ">>> No data disk (LUN 10) detected, skipping disk mount step"
fi

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

# ── Docker ────────────────────────────────────────────────────
echo ">>> Installing Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker azureuser
docker version

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

# ── k9s ───────────────────────────────────────────────────────
echo ">>> Installing k9s..."
K9S_VERSION=$(curl -sSL https://api.github.com/repos/derailed/k9s/releases/latest \
  | jq -r '.tag_name')
curl -sSLO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_linux_amd64.deb"
apt-get install -y ./k9s_linux_amd64.deb
rm -f k9s_linux_amd64.deb
k9s version

# ── kubectl alias ─────────────────────────────────────────────
echo "alias k=kubectl" >> /home/azureuser/.bashrc
echo "alias k=kubectl" >> /root/.bashrc

echo "=== vm-init complete: $(date) ==="
