#!/bin/bash
VAULT_PASSWORD_FILE=".vault_password"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${SCRIPT_DIR}/../ansible

if [ -f "${VAULT_PASSWORD_FILE}" ]; then
    ANSIBLE_ARGS="--vault-password-file ${VAULT_PASSWORD_FILE}"
else
    ANSIBLE_ARGS="--ask-vault-password"
fi

show_help() {
    cat << EOF
Usage: ./run_ansible.sh [-hv] [-e var_name=var_value] [-l | -s <node_name|group_name> | -f <node_name|group_name> | -r playbook.yaml]
Simple bash wrapper around ansible.

-h      Display help
-v      Enable verbose mode
-e      Extra vars
-l      List available playbooks
-s      Show variables for given node
-f      Show facts for given node
-r      Run specific playbook
EOF
}


args=$(getopt hve:ls:f:r: $*)
if [ $? != 0 ]; then
    show_help
    exit 2
fi

set -- $args

EXTRA_VARS=()

for i; do
    case "${i}" in
        -h)
            show_help
            exit 0;;
        -v)
            ANSIBLE_ARGS="${ANSIBLE_ARGS} -v"
            shift;;
        -e)
            EXTRA_VARS+=(${2})
            shift
            shift;;
        -l)
            ACTION="list_playbooks"
            shift;;
        -s)
            ACTION="show_vars"
            HOST=${2}
            shift
            shift;;
        -f)
            ACTION="show_facts"
            HOST=${2}
            shift
            shift;;
        -r)
            ACTION="run_playbook"
            PLAYBOOK=${2}
            shift
            shift;;
        --)
            shift; break;;
    esac
done

case "${ACTION}" in
    run_playbook)
        EXTRA_VARS_FORMATED=""
        if [ "${#EXTRA_VARS[@]}" -gt 0 ]; then
            for val in "${EXTRA_VARS[@]}"; do
                EXTRA_VARS_FORMATED="${EXTRA_VARS_FORMATED} -e ${val}"
            done
        fi
        ansible-playbook ${ANSIBLE_ARGS} ${EXTRA_VARS_FORMATED} playbooks/${PLAYBOOK}
        ;;
    list_playbooks)
        find playbooks/ -type f -maxdepth 1 -exec basename {} \;
        ;;
    show_vars)
        ansible ${ANSIBLE_ARGS} ${HOST} -m debug -a "var=hostvars[inventory_hostname]"
        ;;
    show_facts)
        ansible ${ANSIBLE_ARGS} ${HOST} -m setup
        ;;
    *)
        echo "please provide one of available actions: -l, -s, -f, -r"
        ;;
esac
