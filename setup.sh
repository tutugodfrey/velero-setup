#! /bin/bash

sudo apt update; sudo apt install nfs-common -y
ssh node01 sudo apt update;
ssh node01 sudo apt install nfs-common -y;

# Install CSI DRIVER NFS
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.5.0 --set externalSnapshotter.enabled=true

sleep 20
kubectl apply -f storage-class-csi-driver-nfs.yaml
kubectl apply -f volumesnapshotclass-csi-driver-nfs.yaml
# Install nfs-subdir-external-provisioner
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=44.202.240.228 --set nfs.path=/nfs-datadir --set namespace=kube-system

# Install Velero
VELERO_VERSION=${VELERO_VERSION:-1.12.2}
wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
cp velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

# Run the velero helm deployment
if [[ ! -z $1 ]] && [[ $1 == 'aws' ]]; then
  # Velero with AWS
  cat velero-minio-access-aws.txt | base64 -d > velero-minio-access-aws-decoded.txt
  kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access-aws-decoded.txt --dry-run=client -o yaml > velero-aws-access.yaml
  ./velero-helm-deployment.sh
  kubectl apply -f velero-aws-access.yaml -n velero
  kubectl apply -f velero-repo-credentials.yaml -n velero
  velero client config set features=EnableCSI  # enable csi as part of velero describe

else
  # Velero with MinIO
  cat velero-minio-access.txt | base64 -d > velero-minio-access-decoded.txt
  kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access-decoded.txt --dry-run=client -o yaml > velero-minio-access.yaml
  ./velero-helm-deployment-minio.sh
  kubectl apply -f velero-minio-access.yaml -n velero
  kubectl apply -f velero-repo-credentials.yaml -n velero
  velero client config set features=EnableCSI  # enable csi as part of velero describe

fi

# Install metric server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
