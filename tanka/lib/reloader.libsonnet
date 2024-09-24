{
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
    helm: $._custom.helm.new('reloader', 'https://stakater.github.io/stakater-charts', $._version.reloader.chart, 'kube-system', {
      reloader: {
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
        },
      },
    }),
  },
}
