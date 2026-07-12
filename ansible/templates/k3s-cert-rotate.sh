{%- raw -%}
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

NEEDS_ROTATION=$(k3s certificate check --output json 2>/dev/null | jq '[.Certificates[] | select(.Status != "OK")] | length')

if [ "${NEEDS_ROTATION}" -gt 0 ]; then
    logger --id=$$ -t k3s-cert-rotate "${NEEDS_ROTATION} certificate(s) approaching expiry, rotating"
    k3s certificate rotate
    systemctl restart k3s
    logger --id=$$ -t k3s-cert-rotate "rotation complete"
fi
{% endraw %}
