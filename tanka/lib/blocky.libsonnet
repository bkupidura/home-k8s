{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'blocky',
        rules: [
          {
            alert: 'BlockyFailedDownload',
            expr: 'delta(blocky_failed_download_count[10m]) > 0',
            labels: { service: 'blocky', severity: 'info' },
            annotations: {
              summary: 'Failed downloads increasing on {{ $labels.pod }}',
            },
          },
          {
            alert: 'BlockyErrorsIncreasing',
            expr: 'sum by (pod) (delta(blocky_error_total[5m])) / sum by (pod) (delta(blocky_query_total[5m])) * 100 > 40',
            labels: { service: 'blocky', severity: 'info' },
            annotations: {
              summary: '{{ $value | humanizePercentage }} of queries failing on {{ $labels.pod }}',
            },
          },
          {
            alert: 'BlockyDenylistEmpty',
            expr: 'sum by (pod, group) (blocky_denylist_cache_entries) == 0',
            labels: { service: 'blocky', severity: 'info' },
            annotations: {
              summary: 'Blocky {{ $labels.group }} is empty on {{ $labels.pod }}',
            },
          },
        ],
      },
    ],
  },
  blocky: {
    service: s.new(
               'blocky',
               { 'app.kubernetes.io/name': 'blocky' },
               [v1.servicePort.withPort(53) + v1.servicePort.withProtocol('UDP') + v1.servicePort.withName('blocky')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'blocky' })
             + s.metadata.withAnnotations({ 'metallb.io/loadBalancerIPs': $._config.vip.blocky_dns })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    config: v1.configMap.new('blocky-config', {
              'config.yml': std.manifestYamlDoc({
                ports: { http: 4000, dns: 53 },
                prometheus: { enable: true },
                upstreams: {
                  groups: {
                    default: [std.format('tcp+udp:%s:53', $.coredns.kubelet_cluster_dns)],
                  },
                },
                caching: {
                  maxTime: '-1',
                },
                queryLog: {
                  type: 'none',
                },
                log: { level: 'info', format: 'json', timestamp: true, privacy: true },
                specialUseDomains: {
                  'rfc6762-appendixG': false,
                },
                blocking: {
                  loading: {
                    concurrency: 4,
                    refreshPeriod: '120m',
                    downloads: {
                      timeout: '180s',
                      cooldown: '15s',
                    },
                  },
                  blockType: 'zeroIP',
                  [if std.get($._config.blocky, 'blacklist') != null then 'denylists']: $._config.blocky.blacklist,
                  [if std.get($._config.blocky, 'blacklist') != null then 'clientGroupsBlock']: {
                    default: std.objectFields($._config.blocky.blacklist),
                  },
                },
                [if std.get($._config.blocky, 'conditional') != null then 'conditional']: $._config.blocky.conditional,
                [if std.get($._config.blocky, 'custom_dns') != null then 'customDNS']: $._config.blocky.custom_dns,
              }),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('blocky',
                      2,
                      [
                        c.new('blocky', $._version.blocky.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamedUDP(53, 'dns'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          BLOCKY_CONFIG_FILE: '/config/config.yml',
                        })
                        + c.resources.withRequests({ memory: '256Mi', cpu: '150m' })
                        + c.resources.withLimits({ memory: '256Mi', cpu: '150m' })
                        + c.readinessProbe.tcpSocket.withPort(53)
                        + c.readinessProbe.withInitialDelaySeconds(15)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.tcpSocket.withPort(4000)
                        + c.livenessProbe.withInitialDelaySeconds(240)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'blocky' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.configVolumeMount('blocky-config', '/config/', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                  v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['blocky'] }
                  )
                )
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '4000',
                  'fluentbit.io/parser': 'json',
                }),
  },
}
