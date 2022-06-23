{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  home_assistant: {
    pvc: p.new('home-assistant')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '5Gi' }),
    ingress_route: $._custom.ingress_route.new('home-assistant', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`ha.%s`) && (Path(`/api/websocket`) || Path(`/auth/token`) || Path(`/api/ios/config`) || PathPrefix(`/api/webhook/`))', std.extVar('secrets').domain),
        services: [{ name: 'home-assistant', port: 8123, namespace: 'smart-home' }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
      {
        kind: 'Rule',
        match: std.format('Host(`ha.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'home-assistant', port: 8123, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('home-assistant', 'smart-home', '20 04 * * *', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
    )], 'home-assistant'),
    cronjob_restore: $._custom.cronjob_restore.new('home-assistant', 'smart-home', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host home-assistant --target .', std.extVar('secrets').restic.repo.default)]
    )], 'home-assistant'),
    service: s.new('home-assistant', { 'app.kubernetes.io/name': 'home-assistant' }, [v1.servicePort.withPort(8123) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'home-assistant' }),
    service_lb_tcp: s.new(
                      'home-assistant-vip-tcp',
                      { 'app.kubernetes.io/name': 'home-assistant' },
                      [
                        v1.servicePort.withPort(1400) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('sonos') + v1.servicePort.withTargetPort('sonos'),
                      ]
                    )
                    + s.metadata.withNamespace('smart-home')
                    + s.metadata.withLabels({ 'app.kubernetes.io/name': 'home-assistant' })
                    + s.metadata.withAnnotations({ 'metallb.universe.tf/allow-shared-ip': $._config.vip.home_assistant })
                    + s.spec.withLoadBalancerIP($._config.vip.home_assistant)
                    + s.spec.withType('LoadBalancer')
                    + s.spec.withExternalTrafficPolicy('Local')
                    + s.spec.withPublishNotReadyAddresses(false),
    service_lb_udp: s.new(
                      'home-assistant-vip-udp',
                      { 'app.kubernetes.io/name': 'home-assistant' },
                      [
                        v1.servicePort.withPort(5683) + v1.servicePort.withProtocol('UDP') + v1.servicePort.withName('shelly-coap') + v1.servicePort.withTargetPort('shelly-coap'),
                      ]
                    )
                    + s.metadata.withNamespace('smart-home')
                    + s.metadata.withLabels({ 'app.kubernetes.io/name': 'home-assistant' })
                    + s.metadata.withAnnotations({ 'metallb.universe.tf/allow-shared-ip': $._config.vip.home_assistant })
                    + s.spec.withLoadBalancerIP($._config.vip.home_assistant)
                    + s.spec.withType('LoadBalancer')
                    + s.spec.withExternalTrafficPolicy('Local')
                    + s.spec.withPublishNotReadyAddresses(false),
    deployment: d.new('home-assistant',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('home-assistant', $._version.home_assistant.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8123, 'http'),
                          v1.containerPort.newNamed(1400, 'sonos'),
                          v1.containerPort.newNamedUDP(5683, 'shelly-coap'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '512Mi', cpu: '300m' })
                        + c.resources.withLimits({ memory: '512Mi', cpu: '300m' })
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(120)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'home-assistant' })
                + d.pvcVolumeMount('home-assistant', '/config', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withEnableServiceLinks(true)
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(30)
                + d.spec.template.spec.affinity.podAntiAffinity.withPreferredDuringSchedulingIgnoredDuringExecution(
                  v1.weightedPodAffinityTerm.withWeight(1)
                  + v1.weightedPodAffinityTerm.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.weightedPodAffinityTerm.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['zigbee2mqtt', 'node-red'] }
                  )
                ),
  },
}
