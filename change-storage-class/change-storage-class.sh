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
  # $1 JOB_NAME
  until [[ $(kubectl get job $1 -o jsonpath="{ .status.succeeded}") == 1 ]]; do
    echo Waiting for job $1 to succeed
    sleep 5
  done
}

function wait_for_pvc {
  # $1 PVC_NAME
  until [[ $(kubectl get pvc $1 -o jsonpath="{ .status.phase}") == 'Bound' ]]; do
    echo Waiting for pvc to bound
    sleep 5
  done
}

function wait_for_scaledown {
  # $1 RESOURCE_TYPE
  # $2 RESOURVE_NAME
  if [[ $1 == 'sts' ]] || [[ $1 == 'statefulset' ]]; then
    until [[ $(kubectl get $1 $2 -o jsonpath="{ .status.availableReplicas }") == 0 ]]; do
      echo Wailting for $1 $2 to scale to 0;
      sleep 5;
    done;
  elif [[ $1 == "deploy" ]] || [[ $1 == "deployment" ]]; then
    until [[ $(kubectl get $1 $2 -o jsonpath="{ .status.availableReplicas }") == "" ]]; do
      echo Wailting for $1 $2 to scale to 0;
      sleep 5;
    done;
  fi
}

function change_template_value {
  # $1 PVC_NAME
  # $2 STORAGE_SIZE
  sed "s/PVC_NAME/$1/" copy-data-to-temporary-pvc.yaml > copy-data-to-temporary-pvc-temp.yaml
  sed "s/PVC_NAME/$1/" copy-data-to-dest-pvc.yaml > copy-data-to-dest-pvc-temp.yaml
  sed "s/PVC_NAME/$1/" destination-pvc.yaml > destination-pvc-temp.yaml
  sed -i "s/STORAGE_SIZE/$2/" destination-pvc-temp.yaml
}

function change_storage_class {
  # $1 = PVC_NAME
  # Delete old jobs
  kubectl delete -f copy-data-to-temporary-pvc-temp.yaml
  kubectl delete -f copy-data-to-dest-pvc-temp.yaml
  sleep 5

  kubectl apply -f copy-data-to-temporary-pvc-temp.yaml
  wait_for_job 'copy-data-to-temp-pvc'

  kubectl delete pvc $1 --grace-period=0 --force now
  sleep 5
  kubectl patch pvc $1 --patch '{ "metadata": { "finalizers": null } }'
  sleep 5

  # Create the Destination PVC with new storage class
  kubectl apply -f destination-pvc-temp.yaml
  wait_for_pvc $1
  # COPY data to recreated PVC
  kubectl apply -f copy-data-to-dest-pvc-temp.yaml
  wait_for_job 'copy-data-to-dest-pvc'
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

if [[ $RESOURCE_TYPE == 'sts' ]] || [[ $RESOURCE_TYPE == 'statefulset' ]]; then
  REPLICA_INDEX=$((REPLICAS-1))
  for INDEX in $(bash -c "echo {0..${REPLICA_INDEX}}"); do
    PVC_NAME_STS=${PVC_NAME}-$INDEX
    change_template_value $PVC_NAME_STS $STORAGE_SIZE
    wait_for_scaledown $RESOURCE_TYPE $RESOURCE_NAME;
    change_storage_class $PVC_NAME_STS
  done;
else
  change_template_value $PVC_NAME $STORAGE_SIZE
  wait_for_scaledown $RESOURCE_TYPE $RESOURCE_NAME;
  change_storage_class $PVC_NAME
fi

sleep 5
kubectl scale ${RESOURCE_TYPE} ${RESOURCE_NAME} --replicas=$REPLICAS
