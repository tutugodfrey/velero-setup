#! /bin/bash
# Install kubectl
apt-get update
apt-get install -y wget curl gpg tar
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Install Velero
VELERO_VERSION=${VELERO_VERSION:-1.12.2}
wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
cp velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

# Create Backup
export KUBECONFIG=/kube/kubeconfig
velero backup create ${VELERO_BACKUP_NAME} --selector velero-backup-target=${VELERO_BACKUP_TARGET} --wait

# Keep the pod alive for a while
sleep 400
