#! /bin/bash

# Install Longhorn
./longhorn-helm-deployment.sh
kubectl apply -f longhorn-minio-secret.yaml

# install volumesnapshot crds and snapshot controller
kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=release-5.0"
kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=release-5.0"

# sleep 20

# Crete volumesnapshotclass
sleep 20
kubectl apply -f storage-class-longhorn.yaml
kubectl apply -f volumesnapshotclass-longhorn.yaml
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
  kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access-aws.txt --dry-run=client -o yaml > velero-aws-access.yaml
  sed "s/nfs.csi.k8s.io/driver.longhorn.io/" velero-helm-deployment.sh  > velero-helm-deployment-longhorn.sh
  chmod +x velero-helm-deployment-longhorn.sh
  ./velero-helm-deployment-longhorn.sh
  kubectl apply -f velero-aws-access.yaml -n velero
  kubectl apply -f velero-repo-credentials.yaml -n velero
  velero client config set features=EnableCSI  # enable csi as part of velero describe

else
  # Velero with MinIO
  kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access.txt --dry-run=client -o yaml > velero-minio-access.yaml
  sed "s/nfs.csi.k8s.io/driver.longhorn.io/" velero-helm-deployment-minio.sh > velero-helm-deployment-longhorn.sh
  chmod +x velero-helm-deployment-longhorn.sh
  ./velero-helm-deployment-longhorn.sh
  kubectl apply -f velero-minio-access.yaml -n velero
  kubectl apply -f velero-repo-credentials.yaml -n velero
  velero client config set features=EnableCSI  # enable csi as part of velero describe

fi

# Install metric server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
