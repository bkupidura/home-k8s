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
            std.format('esphome.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:smart-home-infra',
          policy: 'one_factor',
        },
      },
    ],
  },
  esphome: {
    pvc: p.new('esphome')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '3Gi' }),
    service: s.new(
               'esphome',
               { 'app.kubernetes.io/name': 'esphome' },
               [v1.servicePort.withPort(6052) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'esphome' }),
    ingress_route: $._custom.ingress_route.new('esphome', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`esphome.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'esphome', port: 6052, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    cronjob_backup: $._custom.cronjob_backup.new('esphome', 'smart-home', '45 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
                      '\n',
                      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
                    )], 'esphome')
                    + { spec+: { jobTemplate+: { spec+: { template+: { spec+: { affinity: {} } } } } } },
    cronjob_restore: $._custom.cronjob_restore.new('esphome', 'smart-home', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'esphome'),
    deployment: d.new('esphome',
                      0,
                      [
                        c.new('esphome', $._version.esphome.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(6052, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'esphome' })
                + d.pvcVolumeMount('esphome', '/config', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
