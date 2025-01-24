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
            std.format('prowlarr.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:media-download',
          policy: 'one_factor',
        },
      },
    ],
  },
  prowlarr: {
    restore:: $._config.restore,
    pvc: p.new('prowlarr-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('prowlarr', 'arr', '30 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'prowlarr-config'),
    cronjob_restore: $._custom.cronjob_restore.new('prowlarr', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'prowlarr-config'),
    ingress_route: $._custom.ingress_route.new('prowlarr', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`prowlarr.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'prowlarr', port: 9696 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    service: s.new('prowlarr',
                   { 'app.kubernetes.io/name': 'prowlarr' },
                   [
                     v1.servicePort.withPort(9696) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('arr')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'prowlarr' }),
    deployment: d.new('prowlarr',
                      if $.prowlarr.restore then 0 else 1,
                      [
                        c.new('prowlarr', $._version.prowlarr.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(9696, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.resources.withRequests({ memory: '100M', cpu: '75m' })
                        + c.resources.withLimits({ memory: '150M', cpu: '150m' })
                        + c.readinessProbe.httpGet.withPath('/ping')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/ping')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'prowlarr' })
                + d.pvcVolumeMount('prowlarr-config', '/config', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr'),
  },
}
