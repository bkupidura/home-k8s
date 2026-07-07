{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('rss.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:rss',
          policy: 'one_factor',
        },
      },
    ],
  },
  freshrss: {
    restore:: $._config.restore,
    service: s.new('freshrss',
                   { 'app.kubernetes.io/name': 'freshrss' },
                   [
                     v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'freshrss' }),
    ingress_route: $._custom.ingress_route.new('freshrss', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`rss.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'freshrss', port: 80 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    pvc: p.new('freshrss')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '128Mi' }),
    cronjob_backup: $._custom.cronjob_backup.new('freshrss', 'self-hosted', '05 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'freshrss'),
    cronjob_restore: $._custom.cronjob_restore.new('freshrss', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'freshrss'),
    deployment: d.new('freshrss',
                      if $.freshrss.restore then 0 else 1,
                      [
                        c.new('freshrss', $._version.freshrss.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          CRON_MIN: '*/30',
                          TRUSTED_PROXY: $._config.network.kubernetes,
                        })
                        + c.resources.withRequests({ memory: '64Mi', cpu: '100m' })
                        + c.resources.withLimits({ memory: '128Mi', cpu: '130m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withAdd(['SETGID', 'SETUID', 'CHOWN', 'FOWNER', 'DAC_READ_SEARCH', 'DAC_OVERRIDE'])
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/api/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'freshrss' })
                + d.pvcVolumeMount('freshrss', '/var/www/FreshRSS/data', false, {})
                + d.emptyVolumeMount('run', '/run', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.emptyVolumeMount('var-log-apache2', '/var/log/apache2', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.emptyVolumeMount('var-spool-cron', '/var/spool/cron/crontabs', volumeMixin=v1.volume.emptyDir.withSizeLimit('1M'))
                + d.emptyVolumeMount('tmp', '/tmp', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.emptyVolumeMount('php-sessions', '/var/lib/php/sessions', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.spec.template.spec.withInitContainers([
                  c.new('init-run-dirs', $._version.ubuntu.image)
                  + c.withCommand(['/bin/sh', '-c', 'mkdir -p /run/apache2 && chmod 1733 /var/lib/php/sessions'])
                  + c.securityContext.withAllowPrivilegeEscalation(false)
                  + c.securityContext.withReadOnlyRootFilesystem(true)
                  + c.securityContext.capabilities.withDrop('all')
                  + c.withVolumeMounts([
                    v1.volumeMount.new('run', '/run', false),
                    v1.volumeMount.new('php-sessions', '/var/lib/php/sessions', false),
                  ]),
                ])
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.metadata.withAnnotations({ 'fluentbit.io/parser': 'nginx' })
                + d.metadata.withNamespace('self-hosted'),
  },
}
