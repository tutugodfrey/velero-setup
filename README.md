# Velero Setup

[Velero GitHub](https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/README.md)

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




kubectl label pv pvc-19c01e56-00b1-44c7-b0c6-132053332f7a target=backup

kubectl label pv nginx-data target=backup

velero backup create nginx-data-backup --selector target=backup

velero backup describe nginx-data-backup

kubectl delete -f nginx-deployment.yaml 

velero restore create --from-backup nginx-data-backup

velero restore create --from-backup nginx-data-backup --selector target=backup

velero restore create --from-backup nginx-data-backup
```