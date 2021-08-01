#!/bin/bash
STATIC_DIR=./static_generated

mkdir ${STATIC_DIR}
cd ${STATIC_DIR}

kubectl delete configmap static-generated -n home-infra
kubectl create configmap static-generated -n home-infra
