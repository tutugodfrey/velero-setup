# Velero Setup

[Velero GitHub](https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/README.md)

[Cluster Backups with Velero & Longhorn](https://platform.cloudogu.com/en/blog/velero-longhorn-backup-restore/)

Install and configure velero backup and restore procedures

The setup.sh file will install velero cli, create velero minio access secret and deploy velero with helm

```bash
cd velero-setup

./setup.sh
```

Create pvc and pod

```bash
kubectl apply -f nginx-data.yaml
kubectl apply -f nginx-deployment.yaml
```

Kubectl exec into the pod that will be created and add some data in the /mydata directory

```bash
kubectl exec -it nginx-759865db6d-gg69c -- bash

echo Hello world > /mydata/test.txt
echo This is a test backup file >> /mydata/test.txt

exit
```

After the is success, Create a backup of the nginx-data pv that is created

```bash
kubectl get pv   # get the name of the nginx-data pv
velero backup create nginx-data-backup --ordered-resources persistentvolumes=pvc-84ee76ff-2317-4034-a621-9349f7f79e64
```

```bash
velero backup get

velero backup describe nginx-data-backup

velero backup logs nginx-data-backup
```

```bash
kubectl api-resources | grep volumesnapshot

RELEASE_VERSION=6.0
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/release-${RELEASE_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/release-${RELEASE_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/release-${RELEASE_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=release-5.0"
kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=release-5.0"




kubectl label pv pvc-19c01e56-00b1-44c7-b0c6-132053332f7a target=backup

kubectl label pv nginx-data target=backup

velero backup create nginx-data-backup --selector target=backup

velero backup describe nginx-data-backup

kubectl delete -f nginx-deployment.yaml 

velero restore create --from-backup nginx-data-backup

velero restore create --from-backup nginx-data-backup --selector target=backup

velero restore create --from-backup nginx-data-backup
```


```bash
Name:         nginx-data-backup
Namespace:    velero
Labels:       velero.io/storage-location=default
Annotations:  velero.io/resource-timeout=10m0s
              velero.io/source-cluster-k8s-gitversion=v1.28.4
              velero.io/source-cluster-k8s-major-version=1
              velero.io/source-cluster-k8s-minor-version=28

Phase:  Completed


Namespaces:
  Included:  *
  Excluded:  <none>

Resources:
  Included:        *
  Excluded:        <none>
  Cluster-scoped:  auto

Label selector:  target=backup

Or label selector:  <none>

Storage Location:  default

Velero-Native Snapshot PVs:  auto
Snapshot Move Data:          false
Data Mover:                  velero

TTL:  720h0m0s

CSISnapshotTimeout:    10m0s
ItemOperationTimeout:  4h0m0s

Hooks:  <none>

Backup Format Version:  1.1.0

Started:    2024-01-11 17:41:31 +0000 UTC
Completed:  2024-01-11 17:41:34 +0000 UTC

Expiration:  2024-02-10 17:41:30 +0000 UTC

Total items to be backed up:  7
Items backed up:              7

Velero-Native Snapshots: <none included>
```


```bash
velero backup logs nginx-data-backup
```

```bash
...
...
...
time="2024-01-11T17:41:34Z" level=info msg="Backed up 6 items out of an estimated total of 7 (estimate will change throughout the backup)" backup=velero/nginx-data-backup logSource="pkg/backup/backup.go:404" name=local-path-storage namespace= progress= resource=namespaces
time="2024-01-11T17:41:34Z" level=info msg="Processing item" backup=velero/nginx-data-backup logSource="pkg/backup/backup.go:364" name=velero namespace= progress= resource=namespaces
time="2024-01-11T17:41:34Z" level=info msg="Backing up item" backup=velero/nginx-data-backup logSource="pkg/backup/item_backupper.go:177" name=velero namespace= resource=namespaces
time="2024-01-11T17:41:34Z" level=info msg="Backed up 7 items out of an estimated total of 7 (estimate will change throughout the backup)" backup=velero/nginx-data-backup logSource="pkg/backup/backup.go:404" name=velero namespace= progress= resource=namespaces
time="2024-01-11T17:41:34Z" level=info msg="Summary for skipped PVs: [{\"name\":\"pvc-5b4e7fd2-e403-4eec-b438-193eadf3ff36\",\"reasons\":[{\"approach\":\"volumeSnapshot\",\"reason\":\"no applicable volumesnapshotter found\"}]}]" backup=velero/nginx-data-backup logSource="pkg/backup/backup.go:434"
time="2024-01-11T17:41:34Z" level=info msg="Backed up a total of 7 items" backup=velero/nginx-data-backup logSource="pkg/backup/backup.go:436" progress=
```


```bash
root@controlplane:~/velero-setup$ velero restore describe nginx-data-backup-20240111175653
Name:         nginx-data-backup-20240111175653
Namespace:    velero
Labels:       <none>
Annotations:  <none>

Phase:                       Completed
Total items to be restored:  1
Items restored:              1

Started:    2024-01-11 17:56:53 +0000 UTC
Completed:  2024-01-11 17:56:54 +0000 UTC

Backup:  nginx-data-backup

Namespaces:
  Included:  all namespaces found in the backup
  Excluded:  <none>

Resources:
  Included:        *
  Excluded:        nodes, events, events.events.k8s.io, backups.velero.io, restores.velero.io, resticrepositories.velero.io, csinodes.storage.k8s.io, volumeattachments.storage.k8s.io, backuprepositories.velero.io
  Cluster-scoped:  auto

Namespace mappings:  <none>

Label selector:  <none>

Or label selector:  <none>

Restore PVs:  auto

Existing Resource Policy:   <none>
ItemOperationTimeout:       4h0m0s

Preserve Service NodePorts:  auto
```

```bash
root@controlplane:~/velero-setup$ velero restore logs nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="starting restore" logSource="pkg/controller/restore_controller.go:523" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Starting restore of backup velero/nginx-data-backup" logSource="pkg/restore/restore.go:423" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Resource 'persistentvolumes' will be restored at cluster scope" logSource="pkg/restore/restore.go:2295" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Skipping restore of resource because it cannot be resolved via discovery" logSource="pkg/restore/restore.go:2206" resource=clusterclasses.cluster.x-k8s.io restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Skipping restore of resource because it cannot be resolved via discovery" logSource="pkg/restore/restore.go:2206" resource=clusterbootstraps.run.tanzu.vmware.com restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Skipping restore of resource because it cannot be resolved via discovery" logSource="pkg/restore/restore.go:2206" resource=clusters.cluster.x-k8s.io restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Skipping restore of resource because it cannot be resolved via discovery" logSource="pkg/restore/restore.go:2206" resource=clusterresourcesets.addons.cluster.x-k8s.io restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="[debug] Creating factory for /v1, Resource=persistentvolumes in namespace " logSource="pkg/restore/restore.go:1041" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Getting client for /v1, Kind=PersistentVolume" logSource="pkg/restore/restore.go:1007" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=warning msg="Got 0 DataUpload result. Expect one." error="dataupload result number is not expected" logSource="pkg/restore/restore.go:2013" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Dynamically re-provisioning persistent volume because it doesn't have a snapshot and its reclaim policy is Delete." groupResource=persistentvolumes logSource="pkg/restore/restore.go:1333" name=pvc-5b4e7fd2-e403-4eec-b438-193eadf3ff36 namespace= restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Restored 1 items out of an estimated total of 1 (estimate will change throughout the restore)" logSource="pkg/restore/restore.go:755" name=pvc-5b4e7fd2-e403-4eec-b438-193eadf3ff36 namespace= progress= resource=persistentvolumes restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Waiting for all pod volume restores to complete" logSource="pkg/restore/restore.go:635" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Done waiting for all pod volume restores to complete" logSource="pkg/restore/restore.go:651" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Waiting for all post-restore-exec hooks to complete" logSource="pkg/restore/restore.go:655" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="Done waiting for all post-restore exec hooks to complete" logSource="pkg/restore/restore.go:663" restore=velero/nginx-data-backup-20240111175653
time="2024-01-11T17:56:54Z" level=info msg="restore completed" logSource="pkg/controller/restore_controller.go:581" restore=velero/nginx-data-backup-20240111175653
```


```bash
root@controlplane:~/velero-setup$ kubectl get pvc nginx-data -o yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    backup.velero.io/must-include-additional-items: "true"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"annotations":{},"labels":{"app":"sentry"},"name":"nginx-data","namespace":"default"},"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"1Gi"}},"storageClassName":"longhorn","volumeMode":"Filesystem"}}
    velero.io/backup-name: nginx-data-backup
    velero.io/volume-snapshot-name: velero-nginx-data-wl5pk
    volume.beta.kubernetes.io/storage-provisioner: driver.longhorn.io
    volume.kubernetes.io/storage-provisioner: driver.longhorn.io
  creationTimestamp: "2024-01-14T11:38:02Z"
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app: sentry
    backup.velero.io/must-include-additional-items: "true"
    target: backup
    velero.io/backup-name: nginx-data-backup
    velero.io/restore-name: nginx-data-backup-20240114113800
    velero.io/volume-snapshot-name: velero-nginx-data-wl5pk
  name: nginx-data
  namespace: default
  resourceVersion: "10521"
  uid: 26871074-bb39-4f21-aeb5-4b6a63dbd69f
spec:
  accessModes:
  - ReadWriteOnce
  dataSource:
    apiGroup: snapshot.storage.k8s.io
    kind: VolumeSnapshot
    name: velero-nginx-data-wl5pk
  dataSourceRef:
    apiGroup: snapshot.storage.k8s.io
    kind: VolumeSnapshot
    name: velero-nginx-data-wl5pk
  resources:
    requests:
      storage: 1Gi
  storageClassName: longhorn
  volumeMode: Filesystem
status:
  phase: Pending
root@controlplane:~/velero-setup$ 
root@controlplane:~/velero-setup$ 
root@controlplane:~/velero-setup$ kubectl get volumesnapshot velero-nginx-data-wl5pk  -o yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  creationTimestamp: "2024-01-14T11:26:10Z"
  finalizers:
  - snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
  - snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  generateName: velero-nginx-data-
  generation: 1
  labels:
    velero.io/backup-name: nginx-data-backup
  name: velero-nginx-data-wl5pk
  namespace: default
  resourceVersion: "8642"
  uid: b3d653f3-d124-4b85-91ab-2d71a0aec70d
spec:
  source:
    persistentVolumeClaimName: nginx-data
  volumeSnapshotClassName: longhorn-snapshot-vsc
status:
  boundVolumeSnapshotContentName: snapcontent-b3d653f3-d124-4b85-91ab-2d71a0aec70d
  creationTime: "2024-01-14T11:26:10Z"
  readyToUse: true
  restoreSize: 1Gi
root@controlplane:~/velero-setup$ kubectl get volumesnapshotcontent  -o yaml
apiVersion: v1
items:
- apiVersion: snapshot.storage.k8s.io/v1
  kind: VolumeSnapshotContent
  metadata:
    creationTimestamp: "2024-01-14T11:26:10Z"
    finalizers:
    - snapshot.storage.kubernetes.io/volumesnapshotcontent-bound-protection
    generation: 1
    labels:
      velero.io/backup-name: nginx-data-backup
    name: snapcontent-b3d653f3-d124-4b85-91ab-2d71a0aec70d
    resourceVersion: "8656"
    uid: 377defeb-e91c-4cf2-8113-81f90224060e
  spec:
    deletionPolicy: Delete
    driver: driver.longhorn.io
    source:
      volumeHandle: pvc-884900f3-237b-4608-b449-fe566c6d7020
    volumeSnapshotClassName: longhorn-snapshot-vsc
    volumeSnapshotRef:
      apiVersion: snapshot.storage.k8s.io/v1
      kind: VolumeSnapshot
      name: velero-nginx-data-wl5pk
      namespace: default
      resourceVersion: "8627"
      uid: b3d653f3-d124-4b85-91ab-2d71a0aec70d
  status:
    creationTime: 1705231570000000000
    readyToUse: true
    restoreSize: 1073741824
    snapshotHandle: snap://pvc-884900f3-237b-4608-b449-fe566c6d7020/snapshot-b3d653f3-d124-4b85-91ab-2d71a0aec70d
kind: List
metadata:
  resourceVersion: ""
root@controlplane:~/velero-setup$ 
```