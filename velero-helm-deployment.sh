#! /bin/bash

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

helm install velero \
    --namespace=velero \
    --create-namespace \
    --set credentials.existingSecret=velero-minio-access \
    --set configuration.features=EnableCSI \
    --set configuration.backupStorageLocation[0].provider=aws \
    --set configuration.backupStorageLocation[0].name=default \
    --set configuration.backupStorageLocation[0].bucket=velero \
    --set configuration.backupStorageLocation[0].config.region=minio-default \
    --set configuration.backupStorageLocation[0].config.s3ForcePathStyle=true \
    --set configuration.backupStorageLocation[0].config.s3Url=https://minio-s3.dev.compliantcloud.com \
    --set configuration.backupStorageLocation[0].config.publicUrl=https://minio-s3.dev.compliantcloud.com \
    --set snapshotsEnabled=true \
    --set configuration.volumeSnapshotLocation[0].provider=aws \
    --set configuration.volumeSnapshotLocation[0].name=default \
    --set configuration.volumeSnapshotLocation[0].config.region=us-east-1 \
    --set "initContainers[0].name=velero-plugin-for-aws" \
    --set "initContainers[0].image=velero/velero-plugin-for-aws:v1.6.0" \
    --set "initContainers[0].volumeMounts[0].mountPath=/target" \
    --set "initContainers[0].volumeMounts[0].name=plugins" \
    --set "initContainers[1].name=velero-plugin-for-csi" \
    --set "initContainers[1].image=velero/velero-plugin-for-csi:v0.4.0" \
    --set "initContainers[1].volumeMounts[0].mountPath=/target" \
    --set "initContainers[1].volumeMounts[0].name=plugins" \
    vmware-tanzu/velero
