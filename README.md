# Velero Setup

Install and configure velero backup and restore procedures

The setup.sh file will install velero cli, create velero minio access secret and deploy velero with helm

```bash
cd velero-setup

./setup.sh
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
