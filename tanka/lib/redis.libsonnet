{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  redis: {
    pvc: p.new('redis')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '512Mi' }),
    cronjob_backup: $._custom.cronjob_backup.new('redis', 'home-infra', '25 05 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'redis'),
    cronjob_restore: $._custom.cronjob_restore.new('redis', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'redis'),
    service: s.new('redis',
                   { 'app.kubernetes.io/name': 'redis' },
                   [
                     v1.servicePort.withPort(6379) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('redis'),
                   ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'redis' })
             + s.metadata.withAnnotations({ 'metallb.universe.tf/loadBalancerIPs': $._config.vip.redis })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    config: v1.configMap.new('redis-config', {
              'redis.conf': |||
                port 6379
                loglevel notice
                protected-mode no
                dir /data
                save 360 1 60 10
                appendfsync everysec
                appendonly yes
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
                        + c.resources.withRequests({ memory: '8Mi', cpu: '10m' })
                        + c.resources.withLimits({ memory: '32Mi', cpu: '30m' })
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
                + d.pvcVolumeMount('redis', '/data', false, {})
                + d.configVolumeMount('redis-config', '/config/', {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra'),
  },
}
