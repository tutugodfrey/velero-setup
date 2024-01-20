#! /bin/bash

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

helm upgrade --install velero \
    --namespace=velero \
    --create-namespace \
    --set backupsEnabled=true \
    --set snapshotsEnabled=true \
    --set deployNodeAgent=true \
    --set resources.requests.cpu=2m \
    --set resources.requests.memory=50Mi \
    --set resources.limits.cpu=10m \
    --set resources.limits.memory=100Mi \
    --set nodeAgent.resources.requests.cpu=5m \
    --set nodeAgent.resources.requests.memory=200Mi \
    --set nodeAgent.resources.limits.cpu=10m \
    --set nodeAgent.resources.limits.memory=400Mi \
    --set credentials.existingSecret=velero-minio-access \
    --set configuration.logLevel=debug \
    --set configuration.features=EnableCSI \
    --set configuration.backupStorageLocation[0].provider=aws \
    --set configuration.backupStorageLocation[0].name=default \
    --set configuration.backupStorageLocation[0].bucket=velero-backups-728547773713 \
    --set configuration.backupStorageLocation[0].config.region=us-east-1 \
    --set configuration.volumeSnapshotLocation[0].provider=aws \
    --set configuration.volumeSnapshotLocation[0].config.region=us-east-1 \
    --set initContainers[0].name=velero-plugin-for-aws \
    --set initContainers[0].image=velero/velero-plugin-for-aws:v1.8.0 \
    --set initContainers[0].volumeMounts[0].mountPath=/target \
    --set initContainers[0].volumeMounts[0].name=plugins \
    --set initContainers[1].name=velero-plugin-for-csi \
    --set initContainers[1].image=velero/velero-plugin-for-csi:v0.6.3 \
    --set initContainers[1].volumeMounts[0].mountPath=/target \
    --set initContainers[1].volumeMounts[0].name=plugins \
    vmware-tanzu/velero
