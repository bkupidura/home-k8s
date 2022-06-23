#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${SCRIPT_DIR}/../ansible

show_help() {
    cat << EOF
Usage: ./run_ansible.sh [-hv] [-H all] [-e var_name=var_value] [-l | -s | -f | -r playbook.yaml | -c command]
Simple bash wrapper around ansible.

-h      Display help
-v      Enable verbose mode
-e      Extra vars
-H      Host group (used for -s, -f -c)
-l      List available playbooks
-s      Show variables for given node
-f      Show facts for given node
-r      Run specific playbook
-c      Run command
EOF
}


args=$(getopt hve:H:lsfr:c: $*)
if [ $? != 0 ]; then
    show_help
    exit 2
fi

set -- $args

EXTRA_VARS=()
HOST_GROUP=all

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
        -H)
            HOST_GROUP=${2}
            shift
            shift;;
        -l)
            ACTION="list_playbooks"
            shift;;
        -s)
            ACTION="show_vars"
            shift;;
        -f)
            ACTION="show_facts"
            shift;;
        -r)
            ACTION="run_playbook"
            PLAYBOOK=${2}
            shift
            shift;;
        -c)
            ACTION="run_command"
            COMMAND=${2}
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
        ansible ${ANSIBLE_ARGS} ${HOST_GROUP} -m debug -a "var=hostvars[inventory_hostname]"
        ;;
    show_facts)
        ansible ${ANSIBLE_ARGS} ${HOST_GROUP} -m setup
        ;;
    run_command)
        ansible ${ANSIBLE_ARGS} ${HOST_GROUP} -a "${COMMAND}"
        ;;
    *)
        echo "please provide one of available actions: -l, -s, -f, -r, -c"
        ;;
esac
