{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('catalog.%s', std.extVar('secrets').domain),
          ],
          policy: 'one_factor',
        },
      },
    ],
  },
  homer: {
    restore:: $._config.restore,
    pvc: p.new('homer')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '100Mi' }),
    cronjob_backup: $._custom.cronjob_backup.new('homer', 'self-hosted', '50 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'homer'),
    cronjob_restore: $._custom.cronjob_restore.new('homer', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'homer'),
    service: s.new(
               'homer',
               { 'app.kubernetes.io/name': 'homer' },
               [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'homer' }),
    ingress_route: $._custom.ingress_route.new('catalog', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`catalog.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'homer', port: 8080, namespace: 'self-hosted' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    deployment: d.new('homer',
                      if $.homer.restore then 0 else 1,
                      [
                        c.new('homer', $._version.homer.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          INIT_ASSETS: '0',
                        })
                        + c.resources.withRequests({ memory: '10Mi', cpu: '10m' })
                        + c.resources.withLimits({ memory: '20Mi', cpu: '20m' })
                        + c.readinessProbe.httpGet.withPath('/')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'homer' })
                + d.pvcVolumeMount('homer', '/www/assets', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('self-hosted')
                + d.spec.template.spec.securityContext.withFsGroup(1000)
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
