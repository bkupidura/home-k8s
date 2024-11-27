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
        order: 0,
        rule: {
          domain: std.format('sonarr.%s', std.extVar('secrets').domain),
          resources: ['^/api/.*$'],
          networks: [$._config.kubernetes_internal_cidr],
          policy: 'bypass',
        },
      },
      {
        order: 1,
        rule: {
          domain: [
            std.format('sonarr.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:media',
          policy: 'one_factor',
        },
      },
    ],
  },
  sonarr: {
    restore:: $._config.restore,
    pvc: p.new('sonarr-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('sonarr', 'arr', '20 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'sonarr-config'),
    cronjob_restore: $._custom.cronjob_restore.new('sonarr', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'sonarr-config'),
    ingress_route: $._custom.ingress_route.new('sonarr', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`sonarr.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'sonarr', port: 8989 }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }, { name: 'lanhypervisor-whitelist', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    service: s.new('sonarr',
                   { 'app.kubernetes.io/name': 'sonarr' },
                   [
                     v1.servicePort.withPort(8989) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('arr')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'sonarr' }),
    deployment: d.new('sonarr',
                      if $.sonarr.restore then 0 else 1,
                      [
                        c.new('sonarr', $._version.sonarr.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8989, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.resources.withRequests({ memory: '150Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '300Mi', cpu: '100m' })
                        + c.readinessProbe.httpGet.withPath('/')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'sonarr' })
                + d.pvcVolumeMount('sonarr-config', '/config', false, {})
                + d.pvcVolumeMount('media', '/downloads', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr'),
  },
}
