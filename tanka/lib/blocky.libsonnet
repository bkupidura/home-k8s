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
            alert: 'BlockyErrorsIncreasing',
            expr: 'increase(blocky_error_total[10m]) > 10',
            labels: { service: 'blocky', severity: 'info' },
            annotations: {
              summary: 'Errors increasing on {{ $labels.pod }}',
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
             + s.metadata.withAnnotations({ 'metallb.universe.tf/loadBalancerIPs': $._config.vip.dns })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    config: v1.configMap.new('blocky-config', {
              'config.yml': std.manifestYamlDoc({
                ports: { http: 4000, dns: 53 },
                prometheus: { enable: true },
                upstream: {
                  default: ['tcp-tls:8.8.8.8:853', 'tcp-tls:8.8.4.4:853', 'https://1.1.1.1/dns-query', 'https://1.0.0.1/dns-query'],
                },
                caching: {
                  minTime: '2m',
                  maxTime: '10m',
                  maxItemsCount: 10240,
                  cacheTimeNegative: '10m',
                },
                queryLog: {
                  type: 'none',
                },
                log: { level: 'info', format: 'text', timestamp: true },
                blocking: {
                  processingConcurrency: 4,
                  refreshPeriod: '120m',
                  blockType: 'zeroIP',
                  [if $._config.blocky.blacklist != null then 'blackLists']: $._config.blocky.blacklist,
                  [if $._config.blocky.blacklist != null then 'clientGroupsBlock']: {
                    default: std.objectFields($._config.blocky.blacklist),
                  },
                },
                [if $._config.blocky.conditional != null then 'conditional']: $._config.blocky.conditional,
                [if $._config.blocky.custom_dns != null then 'customDNS']: $._config.blocky.custom_dns,
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
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.tcpSocket.withPort(4000)
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'blocky' })
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
                }),
  },
}
