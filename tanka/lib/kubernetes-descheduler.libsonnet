{
  kubernetes_descheduler: {
    network_policy: $._custom.cilium_network_policy.new(
      'descheduler',
      'kube-system',
      { matchLabels: { 'app.kubernetes.io/name': 'descheduler' } },
      ingress=[],
      egress=[
        {
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    helm: $._custom.helm.new('descheduler', 'descheduler', 'https://kubernetes-sigs.github.io/descheduler/', $._version.kubernetes_descheduler.chart, 'kube-system', {
      kind: 'Deployment',
      deschedulingInterval: '10m',
      resources: {
        requests: { cpu: '20m', memory: '32Mi' },
        limits: { cpu: '50m', memory: '64Mi' },
      },
      deschedulerPolicy: {
        profiles: [
          {
            name: 'default',
            pluginConfig: [
              {
                name: 'LowNodeUtilization',
                args: {
                  thresholds: { cpu: 45, memory: 20, pods: 20 },
                  targetThresholds: { cpu: 50, memory: 60, pods: 25 },
                },
              },
              {
                name: 'RemovePodsViolatingInterPodAntiAffinity',
              },
              {
                name: 'PodLifeTime',
                args: {
                  maxPodLifeTimeSeconds: 43200,
                  states: ['Running'],
                  labelSelector: {
                    matchLabels: { 'app.kubernetes.io/name': 'unifi' },
                  },
                },
              },
            ],
            plugins: {
              balance: {
                enabled: ['LowNodeUtilization'],
              },
              deschedule: {
                enabled: ['RemovePodsViolatingInterPodAntiAffinity', 'PodLifeTime'],
              },
            },
          },
        ],
      },
    }),
  },
}
