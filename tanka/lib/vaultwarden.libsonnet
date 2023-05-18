{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  vaultwarden: {
    pvc: p.new('vaultwarden')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '512Mi' }),
    cronjob_backup: $._custom.cronjob.new('vaultwarden-backup',
                                          'home-infra',
                                          '55 04 * * *',
                                          [
                                            c.new('backup', $._version.ubuntu.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('vaultwarden-data', '/data', false),
                                            ])
                                            + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets'))
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'apt update || true',
                                                'apt install -y restic sqlite',
                                                'cd /data',
                                                'sqlite3 db.sqlite3 ".backup db-backup-$(date +%s).dump"',
                                                std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default),
                                              ]),
                                            ]),
                                          ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('vaultwarden')
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                      v1.volume.fromPersistentVolumeClaim('vaultwarden-data', 'vaultwarden'),
                    ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                      v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                      + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                        { key: 'app.kubernetes.io/name', operator: 'In', values: ['vaultwarden'] }
                      )
                    ),
    cronjob_restore: $._custom.cronjob_restore.new('vaultwarden', 'home-infra', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host vaultwarden --target .', std.extVar('secrets').restic.repo.default)]
    )], 'vaultwarden'),
    cronjob_cleanup: $._custom.cronjob.new('vaultwarden-cleanup', 'home-infra', '00 18 * * *', [
                       $.k.core.v1.container.new('cleanup', $._version.ubuntu.image)
                       + $.k.core.v1.container.withVolumeMounts([
                         $.k.core.v1.volumeMount.new('data', '/data', false),
                       ])
                       + $.k.core.v1.container.withCommand([
                         '/bin/sh',
                         '-ec',
                        'find /data -type f -name db-backup-*.dump -mtime +60 -delete',
                       ]),
                     ])
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([$.k.core.v1.volume.fromPersistentVolumeClaim('data', 'vaultwarden')])
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                       $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                       + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['vaultwarden'] }
                       )
                     ),
    ingress_route: $._custom.ingress_route.new('vaultwarden', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`vaultwarden.%s`) && PathPrefix(`/admin`)', std.extVar('secrets').domain),
        services: [{ name: 'vaultwarden', port: 80, namespace: 'home-infra' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
      {
        kind: 'Rule',
        match: std.format('Host(`vaultwarden.%s`) && Path(`/notifications/hub`)', std.extVar('secrets').domain),
        services: [{ name: 'vaultwarden', port: 3012, namespace: 'home-infra' }],
      },
      {
        kind: 'Rule',
        match: std.format('Host(`vaultwarden.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'vaultwarden', port: 80, namespace: 'home-infra' }],
      },
    ], true),
    service: s.new('vaultwarden', { 'app.kubernetes.io/name': 'vaultwarden' }, [
        v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
        v1.servicePort.withPort(3012) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('websockets'),
    ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'vaultwarden' }),
    deployment: d.new('vaultwarden',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('vaultwarden', $._version.vaultwarden.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                          v1.containerPort.newNamed(3012, 'websockets'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          DISABLE_ADMIN_TOKEN: 'true',
                          WEBSOCKET_ENABLED: 'true',
                          DOMAIN: std.format('https://vaultwarden.%s', std.extVar('secrets').domain),
                        })
                        + c.resources.withRequests({ memory: '196Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '196Mi', cpu: '50m' })
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1),
                      ],
                      { 'app.kubernetes.io/name': 'vaultwarden' })
                + d.pvcVolumeMount('vaultwarden', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
