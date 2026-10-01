{
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'reloader', 'io.kubernetes.pod.namespace': 'kube-system' } }], toPorts: [{ ports: [{ port: '9090', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'reloader',
        rules: [
          {
            alert: 'ReloaderFailedReload',
            expr: 'delta(reloader_reload_executed_total{success="false"}[5m]) > 0',
            labels: { service: 'reloader', severity: 'warning' },
            annotations: {
              summary: 'Observed failed CM/secret reloads on {{ $labels.pod }}',
            },
          },
        ],
      },
    ],
  },
  reloader: {
    network_policy: $._custom.cilium_network_policy.new(
      'reloader',
      'kube-system',
      { matchLabels: { 'app.kubernetes.io/name': 'reloader' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9090', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    helm: $._custom.helm.new('reloader', 'reloader', 'https://stakater.github.io/stakater-charts', $._version.reloader.chart, 'kube-system', {
      reloader: {
        readOnlyRootFileSystem: true,
        deployment: {
          resources: {
            requests: { cpu: '15m', memory: '32Mi' },
            limits: { cpu: '30m', memory: '64Mi' },
          },
          pod: {
            annotations: {
              'prometheus.io/scrape': 'true',
              'prometheus.io/port': '9090',
              'fluentbit.io/parser': 'logfmt',
            },
          },
          containerSecurityContext: {
            capabilities: { drop: ['all'] },
            allowPrivilegeEscalation: false,
          },
        },
      },
    }),
  },
}
