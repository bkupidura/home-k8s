{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  nextcloud: {
    update:: $._config.update,
    restore:: $._config.restore,
    pvc: p.new('nextcloud')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '30Gi' }),
    middleware_redirect: $._custom.traefik_middleware.new('nextcloud-redirect', {
      replacePathRegex: {
        regex: '^/.well-known/ca(l|rd)dav',
        replacement: '/remote.php/dav/',
      },
    }),
    ingress_route: $._custom.ingress_route.new('files', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`files.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'nextcloud', port: 80 }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'nextcloud-redirect', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    service: s.new('nextcloud',
                   { 'app.kubernetes.io/name': 'nextcloud' },
                   [
                     v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'nextcloud' }),
    cronjob_backup: $._custom.cronjob_backup.new('nextcloud', 'self-hosted', '00 03,11,19 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'nextcloud'),
    cronjob_restore: $._custom.cronjob_restore.new('nextcloud', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'nextcloud'),
    deployment: d.new('nextcloud',
                      if $.nextcloud.restore then 0 else 1,
                      [
                        c.new('nextcloud', $._version.nextcloud.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('nextcloud', '/var/www/html', false),
                          v1.volumeMount.new('tmp', '/tmp', false),
                          v1.volumeMount.new('var-run', '/var/run', false),
                        ])
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.capabilities.withAdd(['NET_BIND_SERVICE', 'SETUID', 'SETGID', 'DAC_OVERRIDE', 'CHOWN'])
                        + c.securityContext.capabilities.withDrop('all')
                        + (
                          if $.nextcloud.update == false then
                            c.resources.withRequests({ memory: '300M', cpu: '400m' })
                            + c.resources.withLimits({ memory: '400M', cpu: '600m' })
                            + c.readinessProbe.tcpSocket.withPort('http')
                            + c.readinessProbe.withInitialDelaySeconds(10)
                            + c.readinessProbe.withPeriodSeconds(10)
                            + c.readinessProbe.withTimeoutSeconds(1)
                            + c.livenessProbe.httpGet.withPath('/status.php')
                            + c.livenessProbe.httpGet.withHttpHeaders(v1.httpHeader.withName('Host') + v1.httpHeader.withValue(std.format('files.%s', std.extVar('secrets').domain)))
                            + c.livenessProbe.httpGet.withPort('http')
                            + c.livenessProbe.withInitialDelaySeconds(30)
                            + c.livenessProbe.withPeriodSeconds(10)
                            + c.livenessProbe.withTimeoutSeconds(3)
                            + c.securityContext.withReadOnlyRootFilesystem(true)
                          else
                            {}
                        ),
                        c.new('nextcloud-cron', $._version.nextcloud.image)
                        + c.withCommand([
                          '/cron.sh',
                        ])
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withVolumeMounts([
                          v1.volumeMount.new('nextcloud', '/var/www/html', false),
                        ])
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withAdd(['SETUID', 'SETGID'])
                        + c.securityContext.capabilities.withDrop('all')
                        + (if $.nextcloud.update == false then
                             c.resources.withRequests({ memory: '150M' })
                             + c.resources.withLimits({ memory: '300M' })
                             + c.livenessProbe.exec.withCommand([
                               '/bin/bash',
                               '-ec',
                               'ps p1',
                             ])
                             + c.livenessProbe.withInitialDelaySeconds(30)
                             + c.livenessProbe.withPeriodSeconds(15)
                             + c.livenessProbe.withTimeoutSeconds(2)
                           else {}),
                      ],
                      { 'app.kubernetes.io/name': 'nextcloud' })
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromPersistentVolumeClaim('nextcloud', 'nextcloud'),
                  v1.volume.fromEmptyDir('var-run', emptyDir={ sizeLimit: '1M' }),
                  v1.volume.fromEmptyDir('tmp', emptyDir={ sizeLimit: '10G' }),
                ])
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.metadata.withAnnotations({ 'fluentbit.io/parser': 'nginx' })
                + d.metadata.withNamespace('self-hosted'),
  },
}
