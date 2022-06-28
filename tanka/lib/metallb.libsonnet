{
  prometheus+: {
    rules+:: [
      {
        name: 'metallb',
        rules: [
          {
            alert: 'MetalLbBGPDown',
            expr: 'max_over_time(metallb_bgp_session_up[1d]) - metallb_bgp_session_up != 0',
            labels: { service: 'metallb', severity: 'warning' },
            annotations: {
              summary: 'BGP sessions down on {{ $labels.instance }}',
            },
          },
        ],
      },
    ],
  },
  metallb: {
    namespace: $.k.core.v1.namespace.new('metallb-system'),
    helm: $._custom.helm.new(
      'metallb', 'https://metallb.github.io/metallb', $._version.metallb.chart, 'metallb-system', {
        controller: {
          resources: {
            limits: { cpu: '75m', memory: '64Mi' },
          },
          image: {
            repository: $._version.metallb.controller.repo,
            tag: $._version.metallb.controller.tag,
          },
        },
        speaker: {
          resources: {
            limits: { cpu: '75m', memory: '64Mi' },
          },
          image: {
            repository: $._version.metallb.speaker.repo,
            tag: $._version.metallb.speaker.tag,
          },
        },
        prometheus: { scrapeAnnotations: true },
        configInline: $._config.metallb.config,
      }
    ),
  },
}
