{%- raw -%}
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBELET_POD_DIR=/var/lib/kubelet/pods

declare -a PODS
for POD_ID in $(crictl ps -a --no-trunc -o json | jq -r '.containers[].labels."io.kubernetes.pod.uid"'); do
    PODS+=(${POD_ID})
done

for POD_DIR in $(find ${KUBELET_POD_DIR} -maxdepth 1 -mindepth 1 -type d); do
	POD_UID=$(basename ${POD_DIR})
	if [[ ! "${PODS[*]}" =~ "${POD_UID}" ]]; then
                logger --id=$$ -t k3s-stale-pod "removing stale pod ${POD_UID} (${POD_DIR})"
		rm -fr ${POD_DIR}
	fi
done
{% endraw %}
