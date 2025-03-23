{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local st = $.k.storage.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('nzbget.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:media-download',
          policy: 'one_factor',
        },
      },
    ],
  },
  nzbget: {
    restore:: $._config.restore,
    pvc: p.new('nzbget-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('nzbget', 'arr', '35 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'nzbget-config'),
    cronjob_restore: $._custom.cronjob_restore.new('nzbget', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'nzbget-config'),
    ingress_route: $._custom.ingress_route.new('nzbget', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`nzbget.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'nzbget', port: 6789 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    service: s.new('nzbget',
                   { 'app.kubernetes.io/name': 'nzbget' },
                   [
                     v1.servicePort.withPort(6789) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('arr')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'nzbget' }),
    deployment: d.new('nzbget',
                      if $.nzbget.restore then 0 else 1,
                      [
                        c.new('nzbget', $._version.nzbget.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(6789, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          PUID: '911',
                          PGID: '911',
                        })
                        + c.resources.withRequests({ cpu: '150m' })
                        + c.resources.withLimits({ cpu: '300m' })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.readinessProbe.httpGet.withPath('/')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(5)
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'nzbget' })
                + d.pvcVolumeMount('nzbget-config', '/config', false, {})
                + d.pvcVolumeMount('media', '/downloads', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr'),

  },
}
