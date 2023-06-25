{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  trilium: {
    pvc: p.new('trilium')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    cronjob_backup: $._custom.cronjob.new('trilium-backup',
                                          'home-infra',
                                          '00 05 * * *',
                                          [
                                            c.new('backup', $._version.ubuntu.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('trilium', '/data', false),
                                            ])
                                            + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets'))
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'apt update || true',
                                                'apt install -y restic sqlite',
                                                'cd /data',
                                                'sqlite3 document.db ".backup db-backup-$(date +%s).dump"',
                                                std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default),
                                              ]),
                                            ]),
                                          ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('trilium')
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                      v1.volume.fromPersistentVolumeClaim('trilium', 'trilium'),
                    ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                      v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                      + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                        { key: 'app.kubernetes.io/name', operator: 'In', values: ['trilium'] }
                      )
                    ),
    cronjob_restore: $._custom.cronjob_restore.new('trilium', 'home-infra', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host trilium --target .', std.extVar('secrets').restic.repo.default)]
    )], 'trilium'),
    cronjob_cleanup: $._custom.cronjob.new('trilium-cleanup', 'home-infra', '00 18 * * *', [
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
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([$.k.core.v1.volume.fromPersistentVolumeClaim('data', 'trilium')])
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                       $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                       + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['trilium'] }
                       )
                     ),
    service: s.new(
               'trilium',
               { 'app.kubernetes.io/name': 'trilium' },
               [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'trilium' }),
    ingress_route: $._custom.ingress_route.new('trilium', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`trilium.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'trilium', port: 8080, namespace: 'home-infra' }],
        middlewares: [{ name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    deployment: d.new('trilium',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('trilium', $._version.trilium.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          TRILIUM_PORT: '8080',
                          TRILIUM_DATA_DIR: '/data',
                        })
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(5)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/api/health-check')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(3)
                        + c.resources.withRequests({ memory: '256Mi', cpu: '200m' })
                        + c.resources.withLimits({ memory: '256Mi', cpu: '200m' }),
                      ],
                      { 'app.kubernetes.io/name': 'trilium' })
                + d.pvcVolumeMount('trilium', '/data', false, {})
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
