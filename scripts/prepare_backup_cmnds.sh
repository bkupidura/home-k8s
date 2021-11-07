#!/bin/bash
JOBS=$(kubectl get cronjob -A -o jsonpath="{range .items[*]}{.metadata.name}:{.metadata.namespace}{'\n'}{end}")
NOW=$(date +%s)

if [ "$1" == "restore" ]; then
    SUFFIX="-restore$"
else
    SUFFIX="-backup$"
fi

for J in ${JOBS}; do
    JOB_NAME=$(echo ${J} | cut -f1 -d":")
    NAMESPACE=$(echo ${J} | cut -f2 -d":")
    if [[ "${JOB_NAME}" =~ ${SUFFIX} ]]; then
        echo "kubectl create job --from cronjob/${JOB_NAME} ${JOB_NAME}-${NOW} -n ${NAMESPACE}"
    fi
done
