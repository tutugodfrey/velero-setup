#! /bin/bash

PVC_NAME=$1
RESOURCE_NAME=$2
STORAGE_SIZE=$3
RESOURCE_TYPE=deployment
REPLICAS=1

function help() {
  echo Argument 1 is Name of pvc to copy. If PVC is for a statefulset, omit the suffix for the pvc name
  echo Argument 2 name of the resource associated with pvc. e.g deployment or statefulset name
  echo Argument 3 is the storage size of the destination pvc. e.g 10Gi, 200Mi etc
  echo Argument 4 is resource type. e.g deployment, sts
  echo Argument 5 is the number of replicas the deployment or statefulset has

  examples
  1. ./change-pvc-class.sh pvc-name nginx-app-deployment 20Gi deployment
  2. ./change-pvc-class.sh pvc-name nginx-app-deployment 20Gi sts 3
  3. ./change-pvc-class.sh nginx-data-test nginx-test 600Mi deployment 1
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

if [[ ! -z $5 ]]; then
  REPLICAS=$5
fi

# Create temporary pvc
kubectl apply -f temporary-pvc.yaml
sleep 10

# Scale down the deployment
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=0

if [[ $RESOURCE_TYPE == 'sts' ]] || [[ $RESOURCE_TYPE == 'statefulset' ]]; then
  REPLICA_INDEX=$((REPLICAS-1))
  for INDEX in $(bash -c "echo {0..${REPLICA_INDEX}}"); do
    PVC_NAME_STS=${PVC_NAME}-$INDEX
    sed "s/PVC_NAME/${PVC_NAME_STS}/" copy-data-to-temporary-pvc.yaml > copy-data-to-temporary-pvc-temp.yaml
    sed "s/PVC_NAME/${PVC_NAME_STS}/" copy-data-to-dest-pvc.yaml > copy-data-to-dest-pvc-temp.yaml
    sed "s/PVC_NAME/${PVC_NAME_STS}/" destination-pvc.yaml > destination-pvc-temp.yaml
    sed -i "s/STORAGE_SIZE/${STORAGE_SIZE}/" destination-pvc-temp.yaml

    # Delete old jobs
    kubectl delete -f copy-data-to-temporary-pvc-temp.yaml
    kubectl delete -f copy-data-to-dest-pvc-temp.yaml

    kubectl apply -f copy-data-to-temporary-pvc-temp.yaml
    sleep 50

    kubectl delete pvc ${PVC_NAME_STS} --grace-period=0
    sleep 10
    kubectl patch pvc ${PVC_NAME_STS} --patch '{ "metadata": { "finalizers": null } }'

    # Create the Destination PVC with new storage class
    kubectl apply -f destination-pvc-temp.yaml
    sleep 10
    # COPY data to recreated PVC
    kubectl apply -f copy-data-to-dest-pvc-temp.yaml
    sleep 50
    echo $i;
  done;
else
  sed "s/PVC_NAME/${PVC_NAME}/" copy-data-to-temporary-pvc.yaml > copy-data-to-temporary-pvc-temp.yaml
  sed "s/PVC_NAME/${PVC_NAME}/" copy-data-to-dest-pvc.yaml > copy-data-to-dest-pvc-temp.yaml
  sed "s/PVC_NAME/${PVC_NAME}/" destination-pvc.yaml > destination-pvc-temp.yaml
  sed -i "s/STORAGE_SIZE/${STORAGE_SIZE}/" destination-pvc-temp.yaml

  # Delete old jobs
  kubectl delete -f copy-data-to-temporary-pvc-temp.yaml
  kubectl delete -f copy-data-to-dest-pvc-temp.yaml

  kubectl apply -f copy-data-to-temporary-pvc-temp.yaml
  sleep 50
  kubectl delete pvc ${PVC_NAME} --grace-period=0
  sleep 10
  kubectl patch pvc ${PVC_NAME} --patch '{ "metadata": { "finalizers": null } }'

  # Create the Destination PVC with new storage class
  kubectl apply -f destination-pvc-temp.yaml
  sleep 10
  # COPY data to recreated PVC
  kubectl apply -f copy-data-to-dest-pvc-temp.yaml
fi

sleep 50
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=$REPLICAS
