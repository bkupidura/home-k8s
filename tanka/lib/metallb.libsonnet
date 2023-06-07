{
  monitoring+: {
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
          podAnnotations: {
            'prometheus.io/port': '7473',
          },
          frr: { enabled: true },
        },
        prometheus: { scrapeAnnotations: true },
      }
    ),
    address_pool: {
      apiVersion: 'metallb.io/v1beta1',
      kind: 'IPAddressPool',
      metadata: {
        name: 'default',
        namespace: 'metallb-system',
      },
      spec: {
        addresses: $._config.metallb.pool,
      },
    },
    bgp_peer: [
      {
        apiVersion: 'metallb.io/v1beta1',
        kind: 'BGPPeer',
        metadata: {
          name: std.format('peer-%d', idx),
          namespace: 'metallb-system',
        },
        spec: {
          myASN: $._config.metallb.peers[idx].my_asn,
          peerASN: $._config.metallb.peers[idx].asn,
          peerAddress: $._config.metallb.peers[idx].address,
        },
      }
      for idx in std.range(0, std.length($._config.metallb.peers) - 1)
    ],
    bgp_advert: {
      apiVersion: 'metallb.io/v1beta1',
      kind: 'BGPAdvertisement',
      metadata: {
        name: 'default-advert',
        namespace: 'metallb-system',
      },
    },
  },

}
