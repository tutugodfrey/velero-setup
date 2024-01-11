#! /bin/bash

VELERO_VERSION=${VELERO_VERSION:-1.12.2}
wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-v${VELERO_VERSION}-linux-amd64.tar.gz
cp velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

kubectl create namespace velero
kubectl create secret generic velero-minio-access --from-file=cloud=velero-minio-access.txt --dry-run=client -o yaml > velero-minio-access.yaml
kubectl apply -f velero-minio-access.yaml -n velero

# Run the velero helm deployment
./velero-helm-deployment.sh

