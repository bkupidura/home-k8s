#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

STATUS_FILE=/var/run/k3s.health
RETRIES=3
SLEEP=5

HOSTNAME=$(hostname)

function k8s_health() {
    READY_STATUS=$(kubectl get node ${HOSTNAME} -o jsonpath='{.status.conditions[?(@.type == "Ready")].status}' 2> /dev/null)
    if [ "${READY_STATUS}" = "True" ]; then
        echo "running" > ${STATUS_FILE}
        echo 0
    else
        logger --id=$$ -t k3s-health "not running, status ${READY_STATUS}"
        echo 1
    fi
}

RC=$(k8s_health)
if [ "${RC}" -ne 0 ]; then
    while [ "${RETRIES}" -gt 0 ]; do
        sleep ${SLEEP}
        RETRIES=$((${RETRIES} - 1))
        RC=$(k8s_health)
        if [ "${RC}" -eq 0 ]; then
            break
        fi
    done
fi
