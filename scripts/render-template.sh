#!/bin/sh
TEMPLATE_FILE=$1
SERVER_NAME=$2
DATA_FILE=data/config.yaml
JINJA="jinja2 -e jinja2_ansible_filters.AnsibleCoreFiltersExtension"

gpg --decrypt -q --output data/config-tmp.yaml data/config.yaml.gpg

$JINJA data/config-tmp.yaml data/config-tmp.yaml -o ${DATA_FILE}
rm data/config-tmp.yaml

if [ -z "${TEMPLATE_FILE}" ]; then
    for TEMPLATE_FILE in $(find k3shome/manifests -type f -name "*.jinja2"); do
        OUTPUT_FILE=${TEMPLATE_FILE%.*}
        cp ${OUTPUT_FILE} ${OUTPUT_FILE}.tmp 2> /dev/null
        ${JINJA} ${TEMPLATE_FILE} ${DATA_FILE} -o ${OUTPUT_FILE}
        diff ${OUTPUT_FILE} ${OUTPUT_FILE}.tmp >> /dev/null
        if [ "$?" -ne 0 ]; then
            echo "rendered ${TEMPLATE_FILE} as ${OUTPUT_FILE} (changed)"
        else
            echo "rendered ${TEMPLATE_FILE} as ${OUTPUT_FILE}"
        fi
        rm ${OUTPUT_FILE}.tmp 2> /dev/null
    done
else
    ${JINJA} ${TEMPLATE_FILE} ${DATA_FILE} -D server_name=${SERVER_NAME}
fi

rm ${DATA_FILE}
