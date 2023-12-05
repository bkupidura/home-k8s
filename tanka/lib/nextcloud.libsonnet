{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  nextcloud: {
    pvc: p.new('nextcloud')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '20Gi' }),
    middleware_redirect: $._custom.traefik_middleware.new('nextcloud-redirect', {
      replacePathRegex: {
        regex: '^/.well-known/ca(l|rd)dav',
        replacement: '/remote.php/dav/',
      },
    }),
    ingress_route: $._custom.ingress_route.new('files', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`files.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'nextcloud', port: 80 }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'nextcloud-redirect', namespace: 'traefik-system' }],
      },
    ], true),
    service: s.new('nextcloud',
                   { 'app.kubernetes.io/name': 'nextcloud' },
                   [
                     v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'nextcloud' }),
    cronjob_backup: $._custom.cronjob_backup.new('nextcloud', 'home-infra', '00 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'nextcloud'),
    cronjob_restore: $._custom.cronjob_restore.new('nextcloud', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'nextcloud'),
    deployment: d.new('nextcloud',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('nextcloud', $._version.nextcloud.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '256Mi', cpu: '300m' })
                        + c.resources.withLimits({ memory: '512Mi', cpu: '500m' })
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/status.php')
                        + c.livenessProbe.httpGet.withHttpHeaders(v1.httpHeader.withName('Host') + v1.httpHeader.withValue(std.format('files.%s', std.extVar('secrets').domain)))
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(3),
                        c.new('cron', $._version.nextcloud.image)
                        + c.withCommand([
                          '/cron.sh',
                        ])
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.resources.withRequests({ memory: '64Mi' })
                        + c.resources.withLimits({ memory: '128Mi' }),
                      ],
                      { 'app.kubernetes.io/name': 'nextcloud' })
                + d.pvcVolumeMount('nextcloud', '/var/www/html/', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.metadata.withAnnotations({ 'fluentbit.io/parser': 'nginx' })
                + d.metadata.withNamespace('home-infra'),
  },
}
