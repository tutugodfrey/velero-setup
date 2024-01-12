#! /bin/bash

# Install Longhorn
./longhorn-helm-deployment.sh
kubectl apply -f longhorn-minio-secret.yaml

sleep 20

# install volumesnapshot crds and snapshot controller
kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=release-5.0"
kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=release-5.0"

sleep 20

# Crete volumesnapshotclass
kubectl apply -f default-volumesnapshotclass.yaml

sleep 20

VELERO_VERSION=${VELERO_VERSION:-1.12.2}
wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
cp velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access.txt --dry-run=client -o yaml > velero-minio-access.yaml
# Run the velero helm deployment
./velero-helm-deployment.sh
kubectl apply -f velero-minio-access.yaml -n velero

