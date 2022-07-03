{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  prometheus+: {
    rules+:: [
      {
        name: 'broker-ha',
        rules: [
          {
            alert: 'BrokerWrongClusterMembers',
            expr: 'broker_cluster_members != 3',
            'for': '3m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} has wrong number of cluster members',
            },
          },
          {
            alert: 'BrokerUnhealthy',
            expr: 'broker_cluster_member_health > 0',
            'for': '2m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} is unhealthy ',
            },
          },
          {
            alert: 'BrokerFromClusterQueueHigh',
            expr: 'broker_cluster_mqtt_publish_from_cluster > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} is unable to process messages from cluster',
            },
          },
          {
            alert: 'BrokerToClusterQueueHigh',
            expr: 'broker_cluster_mqtt_publish_to_cluster > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} is unable to process messages to cluster',
            },
          },
          {
            alert: 'BrokerPublishDroppedHigh',
            expr: 'broker_publish_dropped > 0',
            'for': '5m',
            labels: {
              service: 'broker-ha',
              severity: 'warning',
            },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} starts dropping publish messages',
            },
          },
          {
            alert: 'BrokerInFlightHigh',
            expr: 'broker_inflight_messages > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} starts reporting in-flight messages',
            },
          },
          {
            alert: 'BrokerRetainedMessagesMismatch',
            expr: 'broker_retained_messages != scalar(max(broker_retained_messages))',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} have different number of retained messages than other cluster members',
            },
          },
        ],
      },
    ],
  },
  broker_ha: {
    service_headless: s.new(
                        'broker-headless',
                        { 'app.kubernetes.io/name': 'broker-ha' },
                        [
                          v1.servicePort.new(7946, 7946)
                          + v1.servicePort.withProtocol('TCP'),
                        ]
                      )
                      + s.metadata.withNamespace('smart-home')
                      + s.metadata.withLabels({ 'app.kubernetes.io/name': 'broker-ha' })
                      + s.spec.withClusterIP('None'),
    service: s.new(
               'mqtt',
               { 'app.kubernetes.io/name': 'broker-ha' },
               [v1.servicePort.withPort(1883) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('mqtt')]
             )
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'mqtt' })
             + s.metadata.withAnnotations({ 'metallb.universe.tf/loadBalancerIPs': $._config.vip.mqtt })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    config: v1.configMap.new('broker-ha-config', {
              'config.yaml': std.manifestYamlDoc({
                discovery: {
                  domain: 'broker-headless.smart-home.svc.cluster.local',
                },
                mqtt: {
                  port: 1883,
                  user: std.extVar('secrets').broker_ha.user,
                },
                cluster: {
                  config: {
                    probe_interval: 500,
                    secret_key: std.extVar('secrets').broker_ha.cluster.config.secret_key,
                  },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('smart-home'),
    deployment: d.new('broker-ha',
                      3,
                      [
                        c.new('broker-ha', $._version.broker_ha.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '32Mi', cpu: '80m' })
                        + c.resources.withLimits({ memory: '32Mi', cpu: '80m' })
                        + c.readinessProbe.httpGet.withPath('/ready')
                        + c.readinessProbe.httpGet.withPort(8080)
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(2)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort(8080)
                        + c.livenessProbe.withInitialDelaySeconds(70)
                        + c.livenessProbe.withPeriodSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'broker-ha' })
                + d.configVolumeMount('broker-ha-config', '/config/', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                  v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['broker-ha'] }
                  )
                )
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(60)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                }),
  },
}
