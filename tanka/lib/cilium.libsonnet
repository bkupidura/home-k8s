{
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          {
            toEntities: ['host', 'remote-node'],
            toPorts: [
              { ports: [
                { port: '9962', protocol: 'TCP' },
                { port: '9963', protocol: 'TCP' },
                { port: '9964', protocol: 'TCP' },
                { port: '9965', protocol: 'TCP' },
              ] },
            ],
          },
        ],
      },
    },
  },
  hubble_relay: {
    network_policy: $._custom.cilium_network_policy.new(
      'hubble-relay',
      'kube-system',
      { matchLabels: { 'app.kubernetes.io/name': 'hubble-relay' } },
      ingress=[
        {
          fromEntities: ['host', 'remote-node'],
          toPorts: [
            { ports: [{ port: '4245', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          toPorts: [
            { ports: [{ port: '53', protocol: 'ANY' }], rules: { dns: [{ matchPattern: '*' }] } },
          ],
        },
        {
          toEntities: ['host', 'remote-node'],
          toPorts: [
            { ports: [{ port: '4244', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
  },
  monitoring+: {
    rules+:: [
      {
        name: 'cilium',
        rules: [
          {
            alert: 'CiliumBGPSessionDown',
            expr: 'max_over_time(cilium_bgp_control_plane_session_state[1d]) - cilium_bgp_control_plane_session_state != 0',
            labels: { service: 'cilium', severity: 'warning' },
            annotations: { summary: 'Cilium BGP session down on {{ $labels.instance }} to peer {{ $labels.neighbor }}' },
          },
          {
            alert: 'CiliumPolicyDeny',
            expr: 'sum(increase_pure(hubble_drop_total{reason=~"POLICY_(DENY|DENIED)"}[5m])) by (source_namespace, source_pod, destination_namespace, destination_pod) > 2',
            labels: { service: 'cilium', severity: 'warning' },
            annotations: { summary: 'Cilium policy is denying traffic from {{ $labels.source_namespace }}/{{ $labels.source_pod }} to {{ $labels.destination_namespace }}/{{ $labels.destination_pod }}' },
          },
        ],
      },
    ],
  },
}
