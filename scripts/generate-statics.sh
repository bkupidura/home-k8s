#!/bin/bash
STATIC_DIR=./static_generated

mkdir ${STATIC_DIR}
cd ${STATIC_DIR}

git clone https://github.com/baarde/cert-manager-webhook-ovh.git || pushd cert-manager-webhook-ovh && git pull && popd
helm package --version=0.0 cert-manager-webhook-ovh/deploy/cert-manager-webhook-ovh/

git clone https://github.com/blakeblackshear/billimek-charts.git || pushd billimek-charts && git pull && popd
helm package --version=0.0 billimek-charts/charts/frigate/

kubectl delete configmap static-generated -n home-infra
kubectl create configmap static-generated -n home-infra \
    --from-file=cert-manager-webhook-ovh-0.0.tgz=cert-manager-webhook-ovh-0.0.tgz \
    --from-file=frigate-0.0.tgz=frigate-0.0.tgz
