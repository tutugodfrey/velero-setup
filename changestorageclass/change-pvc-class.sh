#! /bin/bash

PVC_NAME=$1
RESOURCE_NAME=$2
STORAGE_SIZE=$3
RESOURCE_TYPE=deployment

function help() {
  echo Argument 1 is Name of pvc to copy
  echo Argument 2 name of the resource associated with pvc. e.g deployment or statefulset name
  echo Argument 3 is the storage size of the destination pvc. e.g 10Gi, 200Mi etc
  echo Argument 4 is resource type. e.g deployment, sts

  examples
  1. ./change-pvc-class.sh pvc-name nginx-app-deployment 20Gi deployment
  2. ./change-pvc-class.sh pvc-name nginx-app-deployment 20Gi sts
  exit 0
}


if [[ ! -z $1 ]] && [[ $1 == '--help' ]]; then
  help
elif [[ -z $1 ]] ||  [[ -z $2 ]] ||  [[ -z $3 ]]; then
  help
fi


if [[ ! -z $4 ]]; then
  RESOURCE_TYPE=$4
fi

sed "s/PVC_NAME/${PVC_NAME}/" copy-data-to-temporary-pvc.yaml > copy-data-to-temporary-pvc-temp.yaml
sed "s/PVC_NAME/${PVC_NAME}/" copy-data-to-dest-pvc.yaml > copy-data-to-dest-pvc-temp.yaml
sed "s/PVC_NAME/${PVC_NAME}/" destination-pvc.yaml > destination-pvc-temp.yaml
sed -i "s/STORAGE_SIZE/${STORAGE_SIZE}/" destination-pvc-temp.yaml

# Scale down the deployment
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=0

# Delete old jobs
kubectl delete -f copy-data-to-temporary-pvc-temp.yaml
kubectl delete -f copy-data-to-dest-pvc-temp.yaml

# Create temporary pvc
kubectl apply -f temporary-pvc.yaml
sleep 10

kubectl apply -f copy-data-to-temporary-pvc-temp.yaml
sleep 30
kubectl delete pvc ${PVC_NAME} --grace-period 0 now
sleep 5
kubectl patch pvc nginx-data-test --patch '{ "metadata": { "finalizers": null } }'

sleep 20
# Create the Destination PVC with new storage class
kubectl apply -f destination-pvc-temp.yaml
sleep 10
# COPY data to recreated PVC
kubectl apply -f copy-data-to-dest-pvc-temp.yaml

sleep 30
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=1
