{
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
            expr: 'sum(rate(hubble_drop_total{reason="POLICY_DENIED"}[5m])) by (source_namespace, source_pod, destination_namespace, destination_pod) > 0',
            labels: { service: 'cilium', severity: 'warning' },
            annotations: { summary: 'Cilium policy is denying traffic from {{ $labels.source_namespace }}/{{ $labels.source_pod }} to {{ $labels.destination_namespace }}/{{ $labels.destination_pod }}' },
          },
        ],
      },
    ],
  },
}
