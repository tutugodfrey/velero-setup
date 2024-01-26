#! /bin/bash

PVC_NAME=$1
RESOURCE_NAME=$2
RESOURCE_TYPE=deployment

function help() {
  echo Argument 1 is Name of pvc to copy
  echo Argument 2 name of the resource associated with pvc. e.g deployment or statefulset name
  echo Argument 3 is resource type. e.g deployment, sts
  exit 0
}


if [[ ! -z $1 ]] && [[ $1 == '--help' ]]; then
  help
elif [[ -z $1 ]] ||  [[ -z $2 ]]; then
  help
fi


if [[ ! -z $3 ]]; then
  RESOURCE_TYPE=$3
fi

sed "s/PVC_NAME/${PVC_NAME}/" copy-data-to-hostpath.yaml > copy-data-to-hostpath-temp.yaml
sed "s/PVC_NAME/${PVC_NAME}/" copy-data-to-dest-pvc.yaml > copy-data-to-dest-pvc-temp.yaml
sed "s/PVC_NAME/${PVC_NAME}/" nginx-data-csi-dest.yaml > nginx-data-csi-dest-temp.yaml
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=0

sleep 10

kubectl apply -f copy-data-to-hostpath-temp.yaml
sleep 30
kubectl delete pvc ${PVC_NAME} --grace-period 0 now

sleep 20
# Recreate PVC with new storage class
kubectl apply -f nginx-data-csi-dest-temp.yaml
sleep 10
# COPY data to recreated PVC
kubectl apply -f copy-data-to-dest-pvc-temp.yaml

sleep 30
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=1

rm -rf /destination
