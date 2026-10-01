{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'blocky', 'io.kubernetes.pod.namespace': 'home-infra' } }], toPorts: [{ ports: [{ port: '4000', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'blocky',
        rules: [
          {
            alert: 'BlockyFailedDownload',
            expr: 'delta(blocky_failed_downloads_total[10m]) > 0',
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
    network_policy: $._custom.cilium_network_policy.new(
      'blocky',
      'home-infra',
      { matchLabels: { 'app.kubernetes.io/name': 'blocky' } },
      ingress=[
        {
          fromCIDR: [
            $._config.network.lan,
            $._config.network.iot,
            $._config.network.mgmt,
            $._config.network.guest,
            $._config.network.vpn,
          ],
          toPorts: [
            { ports: [{ port: '53', protocol: 'UDP' }] },
          ],
        },
        {
          fromCIDR: [
            $._config.network.lan,
            $._config.network.iot,
            $._config.network.mgmt,
            $._config.network.guest,
            $._config.network.vpn,
          ],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'DestinationUnreachable' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '4000', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'DestinationUnreachable' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          toPorts: [
            { ports: [{ port: '53', protocol: 'ANY' }] },
          ],
        },
        {
          toCIDR: [std.format('%s/32', $.coredns.kubelet_cluster_dns)],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'DestinationUnreachable' }] },
          ],
        },
        {
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    service: s.new(
               'blocky',
               { 'app.kubernetes.io/name': 'blocky' },
               [v1.servicePort.withPort(53) + v1.servicePort.withProtocol('UDP') + v1.servicePort.withName('blocky')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'blocky' })
             + s.metadata.withAnnotations({ 'lbipam.cilium.io/ips': $._config.vip.blocky_dns })
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
                  maxTime: '-1m',
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
                    concurrency: 1,
                    refreshPeriod: '120m',
                    downloads: {
                      timeout: '240s',
                      readTimeout: '240s',
                      cooldown: '30s',
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
                        + c.resources.withRequests({ memory: '200M', cpu: '100m' })
                        + c.resources.withLimits({ memory: '400M', cpu: '200m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withAdd(['NET_BIND_SERVICE'])
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.tcpSocket.withPort(53)
                        + c.readinessProbe.withInitialDelaySeconds(60)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.tcpSocket.withPort(4000)
                        + c.livenessProbe.withInitialDelaySeconds(180)
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
                  'fluentbit.io/parser': 'json-rfc3339',
                }),
  },
}
