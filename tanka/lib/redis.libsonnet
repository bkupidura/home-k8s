{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  redis: {
    service: s.new('redis',
                   { 'app.kubernetes.io/name': 'redis' },
                   [
                     v1.servicePort.withPort(6379) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('redis'),
                   ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'redis' }),
    config: v1.configMap.new('redis-config', {
              'redis.conf': |||
                port 6379
                loglevel notice
                protected-mode no
                %(acls)s
              ||| % { acls: std.join('\n', std.extVar('secrets').redis.acl) },
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('redis',
                      1,
                      [
                        c.new('redis', $._version.redis.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withCommand([
                          'redis-server',
                          '/config/redis.conf',
                        ])
                        + c.withPorts([
                          v1.containerPort.newNamed(6379, 'redis'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '8Mi', cpu: '20m' })
                        + c.resources.withLimits({ memory: '64Mi', cpu: '50m' })
                        + c.readinessProbe.tcpSocket.withPort('redis')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('redis')
                        + c.livenessProbe.withInitialDelaySeconds(10)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1),
                      ],
                      { 'app.kubernetes.io/name': 'redis' })
                + d.configVolumeMount('redis-config', '/config/', {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra'),
  },
}
