{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
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
            alert: 'BrokerInFlightHigh',
            expr: 'delta(broker_inflight_messages[5m]) > 0',
            'for': '15m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} starts reporting in-flight messages',
            },
          },
          {
            alert: 'BrokerMessagesDropped',
            expr: 'delta(broker_messages_dropped[5m]) > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} starts dropping pub messages',
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
                      + s.metadata.withNamespace('home-infra')
                      + s.metadata.withLabels({ 'app.kubernetes.io/name': 'broker-ha' })
                      + s.spec.withClusterIP('None'),
    service: s.new(
               'mqtt',
               { 'app.kubernetes.io/name': 'broker-ha' },
               [v1.servicePort.withPort(1883) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('mqtt')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'mqtt' })
             + s.metadata.withAnnotations({ 'metallb.io/loadBalancerIPs': $._config.vip.mqtt })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    auth_rendered:: [
      {
        username: username,
        password: std.extVar('secrets').broker_ha.mqtt.users[username].password,
        allow: std.extVar('secrets').broker_ha.mqtt.users[username].allow,
      }
      for username in std.objectFields(std.extVar('secrets').broker_ha.mqtt.users)
    ],
    config: v1.configMap.new('broker-ha-config', {
              'config.yaml': std.manifestYamlDoc({
                api: {
                  user: std.extVar('secrets').broker_ha.api.user,
                },
                discovery: {
                  domain: 'broker-headless.home-infra.svc.cluster.local',
                  subscription_size: {
                    'cluster:message_to': 2048,
                  },
                },
                mqtt: {
                  port: 1883,
                  auth: $.broker_ha.auth_rendered,
                  subscription_size: {
                    'cluster:message_from': 2048,
                    'cluster:new_member': 10,
                  },
                },
                cluster: {
                  config: {
                    probe_interval: 500,
                    push_pull_interval: 20000,
                    secret_key: std.extVar('secrets').broker_ha.cluster.config.secret_key,
                  },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('broker-ha',
                      3,
                      [
                        c.new('broker-ha', $._version.broker_ha.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '64Mi', cpu: '100m' })
                        + c.resources.withLimits({ memory: '64Mi', cpu: '100m' })
                        + c.readinessProbe.httpGet.withPath('/ready')
                        + c.readinessProbe.httpGet.withPort(8080)
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(2)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort(8080)
                        + c.livenessProbe.withInitialDelaySeconds(70)
                        + c.livenessProbe.withPeriodSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'broker-ha' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.configVolumeMount('broker-ha-config', '/config/', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.spec.template.spec.affinity.podAntiAffinity.withPreferredDuringSchedulingIgnoredDuringExecution(
                  v1.weightedPodAffinityTerm.withWeight(1)
                  + v1.weightedPodAffinityTerm.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.weightedPodAffinityTerm.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['broker-ha'] }
                  )
                )
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(60)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                }),
  },
}
