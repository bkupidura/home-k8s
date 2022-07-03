{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.daemonSet,
  chrony: {
    service: s.new(
               'chrony',
               { 'app.kubernetes.io/name': 'chrony' },
               [v1.servicePort.withPort(123) + v1.servicePort.withProtocol('UDP') + v1.servicePort.withName('chrony')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'chrony' })
             + s.metadata.withAnnotations({ 'metallb.universe.tf/loadBalancerIPs': $._config.vip.ntp })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    daemonset: d.new('chrony',
                     [
                       c.new('chrony', $._version.chrony.image)
                       + c.withImagePullPolicy('IfNotPresent')
                       + c.withPorts(v1.containerPort.newNamedUDP(123, 'ntp'))
                       + c.withEnvMap({
                         TZ: $._config.tz,
                         CHRONY_ALLOW: std.join(',', $._config.chrony.allow),
                         CHRONY_POOL: $._config.chrony.pool,
                         CHRONY_SYNC_RTC: 'true',
                       })
                       + c.withVolumeMounts([
                         v1.volumeMount.new('etc-localtime', '/etc/localtime', true),
                         v1.volumeMount.new('etc-timezone', '/etc/timezone', true),
                       ])
                       + c.resources.withRequests({ memory: '8Mi' })
                       + c.resources.withLimits({ memory: '16Mi' })
                       + c.securityContext.capabilities.withAdd('SYS_TIME')
                       + c.readinessProbe.exec.withCommand(['chronyc', 'tracking'])
                       + c.readinessProbe.withInitialDelaySeconds(30)
                       + c.readinessProbe.withPeriodSeconds(60)
                       + c.livenessProbe.exec.withCommand(['chronyc', 'tracking'])
                       + c.livenessProbe.withInitialDelaySeconds(30)
                       + c.livenessProbe.withPeriodSeconds(60)
                       + c.livenessProbe.withTimeoutSeconds(5),
                     ],
                     { 'app.kubernetes.io/name': 'chrony' })
               + d.metadata.withNamespace('home-infra')
               + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
               + d.spec.template.spec.withVolumes([
                 v1.volume.fromHostPath('etc-localtime', '/etc/localtime') + v1.volume.hostPath.withType('File'),
                 v1.volume.fromHostPath('etc-timezone', '/etc/timezone') + v1.volume.hostPath.withType('File'),
               ]),
  },
}
