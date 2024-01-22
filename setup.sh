#! /bin/bash

# Install Longhorn
# ./longhorn-helm-deployment.sh
# kubectl apply -f longhorn-minio-secret.yaml

# sleep 20

# install volumesnapshot crds and snapshot controller
# kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=release-5.0"
# kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=release-5.0"

# sleep 20

# Crete volumesnapshotclass

sudo apt update; sudo apt install nfs-common -y
ssh node01 sudo apt update;
ssh node01 sudo apt install nfs-common -y;

# Install CSI DRIVER NFS
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.5.0 --set externalSnapshotter.enabled=true

sleep 20
kubectl apply -f csi-storage-class.yaml
kubectl apply -f volumesnapshotclass.yaml
# Install nfs-subdir-external-provisioner
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=44.202.240.228 --set nfs.path=/nfs-datadir --set namespace=kube-system

# Install Velero
VELERO_VERSION=${VELERO_VERSION:-1.12.2}
wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
cp velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access-aws.txt --dry-run=client -o yaml > velero-minio-access.yaml
# kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access.txt --dry-run=client -o yaml > velero-minio-access.yaml
# Run the velero helm deployment
./velero-helm-deployment.sh
kubectl apply -f velero-minio-access.yaml -n velero
velero client config set features=EnableCSI  # enable csi as part of velero describe
# Install metric server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
