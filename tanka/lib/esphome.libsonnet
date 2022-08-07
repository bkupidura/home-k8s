{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  esphome: {
    pvc: p.new('esphome')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '2Gi' }),
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
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('esphome', 'smart-home', '40 04 * * *', ['/bin/sh', '-ec', std.join(
                      '\n',
                      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
                    )], 'esphome')
                    + { spec+: { jobTemplate+: { spec+: { template+: { spec+: { affinity: {} } } } } } },
    cronjob_restore: $._custom.cronjob_restore.new('esphome', 'smart-home', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host esphome --target .', std.extVar('secrets').restic.repo.default)]
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
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
