{
  kubernetes_descheduler: {
    helm: $._custom.helm.new('descheduler', 'https://kubernetes-sigs.github.io/descheduler/', $._version.kubernetes_descheduler.chart, 'kube-system', {
      kind: 'Deployment',
      deschedulingInterval: '10m',
      resources: {
        requests: { cpu: '20m', memory: '32Mi' },
        limits: { cpu: '50m', memory: '64Mi' },
      },
      deschedulerPolicy: {
        strategies: {
          RemoveDuplicates: { enabled: false },
          RemovePodsViolatingNodeTaints: { enabled: false },
          RemovePodsViolatingNodeAffinity: { enabled: false },
          RemovePodsViolatingInterPodAntiAffinity: {
            enabled: true,
            params: {
              nodeFit: true,
            },
          },
          LowNodeUtilization: {
            enabled: true,
            params: {
              nodeFit: true,
              nodeResourceUtilizationThresholds: {
                thresholds: { cpu: 45, memory: 20, pods: 15 },
                targetThresholds: { cpu: 50, memory: 60, pods: 25 },
              },
            },
          },
          PodLifeTime: {
            enabled: true,
            params: {
              podLifeTime: { maxPodLifeTimeSeconds: 86400 },
              podStatusPhases: ['Running'],
              labelSelector: {
                matchLabels: { 'app.kubernetes.io/name': 'unifi' },
              },
            },
          },
        },
      },
    }),
  },
}
