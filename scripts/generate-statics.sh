#!/bin/bash
STATIC_DIR=./static_generated

mkdir ${STATIC_DIR}
cd ${STATIC_DIR}

git clone https://github.com/blakeblackshear/billimek-charts.git || pushd billimek-charts && git pull && popd
helm package --version=0.0 billimek-charts/charts/frigate/

kubectl delete configmap static-generated -n home-infra
kubectl create configmap static-generated -n home-infra \
    --from-file=frigate-0.0.tgz=frigate-0.0.tgz
