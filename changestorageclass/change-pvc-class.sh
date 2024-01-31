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

function wait_for_job {
  until [[ $(kubectl get job $1 -o jsonpath="{ .status.succeeded}") == 1 ]]; do
    echo Waiting for job $1 to succeed
    sleep 5
  done
}

function wait_for_pvc {
  until [[ $(kubectl get pvc $1 -o jsonpath="{ .status.phase}") == 'Bound' ]]; do
    echo Waiting for pvc to bound
    sleep 5
  done
}

function wait_for_pod_scaledown {
  until [[ $(kubectl get $1 $2 -o jsonpath="{ .status.availableReplicas }") == 0 ]]; do
    echo Wailting for $1 $2 to scale to 0;
    sleep 5;
  done;
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
wait_for_pvc 'temporary-pvc'

# Scale down the deployment and wait for until scale to 0
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=0
wait_for_pod_scaledown $RESOURCE_TYPE $RESOURCE_NAME;

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
    sleep 5

    kubectl apply -f copy-data-to-temporary-pvc-temp.yaml
    wait_for_job 'copy-data-to-temp-pvc'

    kubectl delete pvc ${PVC_NAME_STS} --grace-period=0 --force now
    sleep 5
    kubectl patch pvc ${PVC_NAME_STS} --patch '{ "metadata": { "finalizers": null } }'
    sleep 5

    # Create the Destination PVC with new storage class
    kubectl apply -f destination-pvc-temp.yaml
    wait_for_pvc $PVC_NAME_STS

    # COPY data to recreated PVC
    kubectl apply -f copy-data-to-dest-pvc-temp.yaml
    wait_for_job 'copy-data-to-dest-pvc'
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
  sleep 5

  kubectl apply -f copy-data-to-temporary-pvc-temp.yaml
  wait_for_job 'copy-data-to-temp-pvc'

  kubectl delete pvc ${PVC_NAME} --grace-period=0 --force now
  sleep 5
  kubectl patch pvc ${PVC_NAME} --patch '{ "metadata": { "finalizers": null } }'
  sleep 5

  # Create the Destination PVC with new storage class
  kubectl apply -f destination-pvc-temp.yaml
  wait_for_pvc $PVC_NAME_STS
  # COPY data to recreated PVC
  kubectl apply -f copy-data-to-dest-pvc-temp.yaml
  wait_for_job 'copy-data-to-dest-pvc'
fi

sleep 5
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=$REPLICAS
