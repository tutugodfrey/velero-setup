#! /bin/bash

echo Hello world

if [[ ! -z $2 ]]; then
  RESOURCE_TYPE=$2
fi

REPLICAS=1
if [[ ! -z $1 ]]; then
  REPLICAS=$1
fi

echo REPLICAS is $REPLICAS

if [[ $RESOURCE_TYPE == 'sts' ]] || [[ $RESOURCE_TYPE == 'statefulset' ]]; then
  REPLICA_INDEX=$((REPLICAS-1))
  echo Relica index is $REPLICA_INDEX
  # for INDEX in {0..$REPLICA_INDEX}; do
  for INDEX in $(bash -c "echo {0..${REPLICA_INDEX}}"); do
    echo Index is $INDEX
    PVC_NAME_STS=${PVC_NAME}-$INDEX
    echo $PVC_NAME_STS
  done

fi

# if [[ ! -z $1 ]] && [[ $1 == 'minio' ]]; then
#   echo hahaha
# else
#   echo Gehgeh
# fi
