#! /bin/bash

echo Hello world


if [[ ! -z $1 ]] && [[ $1 == 'minio' ]]; then
  echo hahaha
else
  echo Gehgeh
fi
