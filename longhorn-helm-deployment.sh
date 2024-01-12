#! /bin/bash

helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn \
    longhorn/longhorn \
    --namespace longhorn-system \
    --create-namespace \
    --values longhorn-values.yaml \
    --version 1.4.0

