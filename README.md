# Velero Setup

[Velero GitHub](https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/README.md)

[Cluster Backups with Velero & Longhorn](https://platform.cloudogu.com/en/blog/velero-longhorn-backup-restore/)

[longhorn](https://github.com/longhorn/longhorn/)

## ALTERNATIVE TO VELERO
[TRILLO](https://docs.trilio.io/trilio-data)

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

kubectl label pv pvc-19c01e56-00b1-44c7-b0c6-132053332f7a velero-backup-target=velero-dev-backup-test   # Label the PV

velero backup create dev-backup-tt-2 --selector velero-backup-target=velero-dev-backup-test --snapshot-move-data --wait
velero backup create nginx-data-backup --ordered-resources persistentvolumes=pvc-84ee76ff-2317-4034-a621-9349f7f79e64

velero backup create dev-backup-tt-2 --selector velero-backup-target=velero-dev-backup-test --snapshot-move-data --wait # --snapshot-move-data allows snapshot data to be pushed to backend storage. 
```

```bash
velero backup get

velero backup describe nginx-data-backup

velero backup logs nginx-data-backup
```

# Restore a backup

```bash
velero restore create dev-backup-tt-2-restore-6 --from-backup dev-backup-tt-2  --include-namespaces=velero,default --wait # It was necessary to include the velero namespace in the restore target. Else the restore didn't work. Then it become necessary to include the namesapces to restore in the restore target else nothing is restore, only the velero namespace is restore
```

```bash
kubectl api-resources | grep volumesnapshot

RELEASE_VERSION=6.0
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/release-${RELEASE_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/release-${RELEASE_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/release-${RELEASE_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=release-5.0"
kubectl -n kube-system create -k "github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=release-5.0"

helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.5.0 --set externalSnapshotter.enabled=true

kubectl label pv nginx-data target=backup

velero backup create nginx-data-backup --selector target=backup

velero backup describe nginx-data-backup

kubectl delete -f nginx-deployment.yaml 

velero restore create --from-backup nginx-data-backup

velero restore create --from-backup nginx-data-backup --selector target=backup

velero restore create --from-backup nginx-data-backup
```

```bash
./change-pvc-class.sh mongo-data-mongo-st mongo-st 600M sts 3
```

<!-- job copy-data-to-temp-pvc

status:
  completionTime: "2024-01-31T02:35:38Z"
  conditions:
  - lastProbeTime: "2024-01-31T02:35:38Z"
    lastTransitionTime: "2024-01-31T02:35:38Z"
    status: "True"
    type: Complete
  ready: 0
  startTime: "2024-01-31T02:34:52Z"
  succeeded: 1
  terminating: 0
  uncountedTerminatedPods: {} -->


# Longhorn Deployment

```bash
./longhorn-helm-deployment.sh

For encrypted volume
kubectl apply -f longhorn-encryption-secret.yaml
kubectl apply -f longhorn-encryption-storageclass.yaml
kubectl apply -f mssql-pvc.yaml
kubectl apply -f pod1.yaml
```