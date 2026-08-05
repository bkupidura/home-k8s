{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    extra_scrape+:: {
      immich: {
        job_name: 'immich',
        metrics_path: '/metrics',
        scheme: 'http',
        scrape_interval: '10s',
        static_configs: [
          { targets: ['immich.self-hosted:8081', 'immich.self-hosted:8082'] },
        ],
      },
    },
  },
  immich: {
    update:: $._config.update,
    restore:: $._config.restore,
    pvc_immich: p.new('immich-data')
                + p.metadata.withNamespace('self-hosted')
                + p.spec.withAccessModes(['ReadWriteOnce'])
                + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
                + p.spec.resources.withRequests({ storage: '70Gi' }),
    pvc_postgres: p.new('immich-postgres')
                  + p.metadata.withNamespace('self-hosted')
                  + p.spec.withAccessModes(['ReadWriteOnce'])
                  + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
                  + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route: $._custom.ingress_route.new('photos', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`photos.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'immich', port: 2283 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], true),
    service_immich: s.new('immich', { 'app.kubernetes.io/name': 'immich' }, [
                      v1.servicePort.withPort(2283) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                      v1.servicePort.withPort(8081) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('api-metrics'),
                      v1.servicePort.withPort(8082) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('ms-metrics'),
                    ])
                    + s.metadata.withLabels({ 'app.kubernetes.io/name': 'immich' })
                    + s.metadata.withNamespace('self-hosted'),
    service_postgres: s.new('immich-postgres', { 'app.kubernetes.io/name': 'immich-postgres' }, [v1.servicePort.withPort(5432) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('postgres')])
                      + s.metadata.withNamespace('self-hosted')
                      + s.metadata.withLabels({ 'app.kubernetes.io/name': 'immich-postgres' }),
    secret: v1.secret.new('immich-secrets', {
      DB_PASSWORD: std.base64(std.extVar('secrets').immich.postgres.password),
      REDIS_PASSWORD: std.base64(std.extVar('secrets').immich.valkey.password),
    }) + v1.secret.metadata.withNamespace('self-hosted'),
    secret_postgres: v1.secret.new('immich-postgres-secrets', {
      POSTGRES_PASSWORD: std.base64(std.extVar('secrets').immich.postgres.password),
      PGPASSWORD: std.base64(std.extVar('secrets').immich.postgres.password),
    }) + v1.secret.metadata.withNamespace('self-hosted'),
    config_postgres: v1.configMap.new('immich-postgres-config', {
                       'postgresql.override.conf': |||
                         listen_addresses = '*'
                         max_wal_size = 512MB
                         shared_buffers = 128MB
                       |||,
                     })
                     + v1.configMap.metadata.withNamespace('self-hosted'),
    cronjob_backup_postgres: $._custom.cronjob.new('immich-postgres-backup',
                                                   'self-hosted',
                                                   '55 04,20 * * *',
                                                   [
                                                     c.new('backup', $._version.restic.image)
                                                     + c.withVolumeMounts([
                                                       v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                       v1.volumeMount.new('workdir', '/data', false),
                                                     ])
                                                     + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                                     + c.withCommand([
                                                       '/bin/sh',
                                                       '-ec',
                                                       std.join('\n', [
                                                         'cd /data',
                                                         'restic --verbose backup .',
                                                       ]),
                                                     ]),
                                                   ],
                                                   [
                                                     c.new('pre-backup', $._version.immich.postgres)
                                                     + c.withVolumeMounts([
                                                       v1.volumeMount.new('workdir', '/data', false),
                                                     ])
                                                     + c.withEnvFrom([v1.envFromSource.secretRef.withName('immich-postgres-secrets')])
                                                     + c.withCommand([
                                                       '/bin/sh',
                                                       '-ec',
                                                       std.join('\n', [
                                                         'cd /data',
                                                         'pg_dumpall -U postgres -h immich-postgres.self-hosted -f db-backup-$(date +%%d-%%m-%%YT%%H:%%M:%%S).sql',
                                                       ]),
                                                     ]),
                                                   ])
                             + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('immich-postgres')
                             + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                               v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                               { name: 'workdir', emptyDir: {} },
                             ]),
    cronjob_restore_postgres: $._custom.cronjob.new('immich-postgres-restore',
                                                    'self-hosted',
                                                    '0 0 * * *',
                                                    [
                                                      c.new('restore', $._version.immich.postgres)
                                                      + c.withVolumeMounts([
                                                        v1.volumeMount.new('workdir', '/data', false),
                                                      ])
                                                      + c.withEnvFrom([v1.envFromSource.secretRef.withName('immich-postgres-secrets')])
                                                      + c.withCommand([
                                                        '/bin/sh',
                                                        '-ec',
                                                        std.join('\n', [
                                                          'cd /data',
                                                          'LATEST=`find . -type f -printf "%T+ %p\n" | sort -r | head  -1 | cut -f2 -d" "`',
                                                          'echo using $LATEST backup',
                                                          'psql -U postgres -h immich-postgres.self-hosted -f $LATEST',
                                                        ]),
                                                      ]),
                                                    ],
                                                    [
                                                      c.new('pre-restore', $._version.restic.image)
                                                      + c.withVolumeMounts([
                                                        v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                        v1.volumeMount.new('workdir', '/data', false),
                                                      ])
                                                      + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                                      + c.withEnvMap({
                                                        RESTIC_HOST: 'immich-postgres',
                                                      })
                                                      + c.withCommand([
                                                        '/bin/sh',
                                                        '-ec',
                                                        std.join('\n', [
                                                          'cd /data',
                                                          'restic --verbose restore latest -H immich-postgres --target .',
                                                        ]),
                                                      ]),
                                                    ])
                              + $.k.batch.v1.cronJob.spec.withSuspend(true)
                              + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('immich-postgres')
                              + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                                { name: 'workdir', emptyDir: {} },
                              ]),
    cronjob_backup_immich: $._custom.cronjob_backup.new('immich', 'self-hosted', '00 05,21 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'immich-data'),
    cronjob_restore_immich: $._custom.cronjob_restore.new('immich', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'immich-data'),
    deployment_immich: d.new('immich',
                             if $.immich.restore then 0 else 1,
                             [
                               c.new('immich', $._version.immich.image)
                               + c.withImagePullPolicy('IfNotPresent')
                               + c.withPorts([v1.containerPort.newNamed(2283, 'http'), v1.containerPort.newNamed(8081, 'api-metrics'), v1.containerPort.newNamed(8082, 'ms-metrics')])
                               + c.withEnvMap({
                                 TZ: $._config.tz,
                                 DB_HOSTNAME: 'immich-postgres.self-hosted',
                                 DB_PORT: '5432',
                                 DB_DATABASE_NAME: 'immich',
                                 DB_USERNAME: 'postgres',
                                 DB_VECTOR_EXTENSION: 'vectorchord',
                                 REDIS_HOSTNAME: 'valkey.home-infra',
                                 REDIS_USERNAME: 'immich',
                                 IMMICH_TELEMETRY_INCLUDE: 'all',
                                 IMMICH_PORT: '2283',
                               })
                               + c.withEnvFrom([v1.envFromSource.secretRef.withName('immich-secrets')])
                               + c.securityContext.withAllowPrivilegeEscalation(false)
                               + c.securityContext.withReadOnlyRootFilesystem(true)
                               + c.securityContext.capabilities.withDrop('all')
                               + (
                                 if $.immich.update == false then
                                   c.resources.withRequests({ cpu: '250m', memory: '700M' })
                                   + c.resources.withLimits({ cpu: '400m', memory: '1600M', 'devic.es/video-dri': 1 })
                                   + c.livenessProbe.httpGet.withPath('/api/server/ping')
                                   + c.livenessProbe.httpGet.withPort('http')
                                   + c.livenessProbe.withInitialDelaySeconds(90)
                                   + c.livenessProbe.withPeriodSeconds(10)
                                   + c.livenessProbe.withTimeoutSeconds(2)
                                   + c.readinessProbe.httpGet.withPath('/api/server/ping')
                                   + c.readinessProbe.httpGet.withPort('http')
                                   + c.readinessProbe.withInitialDelaySeconds(30)
                                   + c.readinessProbe.withPeriodSeconds(10)
                                   + c.readinessProbe.withTimeoutSeconds(2)
                                 else
                                   c.resources.withLimits({ 'devic.es/video-dri': 1 })
                               ),
                             ],
                             { 'app.kubernetes.io/name': 'immich' })
                       + d.spec.template.spec.withNodeSelector({ video_processing: 'true' })
                       + d.pvcVolumeMount('immich-data', '/usr/src/app/upload', false, {})
                       + d.spec.strategy.withType('Recreate')
                       + d.metadata.withNamespace('self-hosted')
                       + d.spec.template.spec.withTerminationGracePeriodSeconds(10),
    deployment_postgres: d.new('immich-postgres',
                               1,
                               [
                                 c.new('postgres', $._version.immich.postgres)
                                 + c.withImagePullPolicy('IfNotPresent')
                                 + c.withPorts(v1.containerPort.newNamed(5432, 'postgres'))
                                 + c.withEnvMap({
                                   TZ: $._config.tz,
                                   POSTGRES_INITDB_ARGS: '--data-checksums',
                                   POSTGRES_USER: 'postgres',
                                   POSTGRES_DB: 'immich',
                                   PGDATA: '/var/lib/postgresql/data/pgdata',
                                 })
                                 + c.withEnvFrom([v1.envFromSource.secretRef.withName('immich-postgres-secrets')])
                                 + c.withVolumeMounts([
                                   v1.volumeMount.new('etc-postgresql', '/etc/postgresql', false),
                                   v1.volumeMount.new('immich-postgres', '/var/lib/postgresql/data', false),
                                   v1.volumeMount.new('var-run-postgresql', '/var/run/postgresql', false),
                                 ])
                                 + c.securityContext.withAllowPrivilegeEscalation(false)
                                 + c.securityContext.withReadOnlyRootFilesystem(true)
                                 + c.securityContext.capabilities.withAdd(['DAC_OVERRIDE', 'FOWNER', 'SETUID', 'SETGID', 'CHOWN'])
                                 + c.securityContext.capabilities.withDrop('all')
                                 + (if $.immich.update == false then
                                      c.resources.withRequests({ cpu: '200m', memory: '200M' })
                                      + c.resources.withLimits({ cpu: '350m', memory: '300M' })
                                      + c.readinessProbe.exec.withCommand(['/usr/local/bin/healthcheck.sh'])
                                      + c.readinessProbe.withInitialDelaySeconds(20)
                                      + c.readinessProbe.withPeriodSeconds(15)
                                      + c.readinessProbe.withTimeoutSeconds(3)
                                      + c.livenessProbe.exec.withCommand(['/usr/local/bin/healthcheck.sh'])
                                      + c.livenessProbe.withInitialDelaySeconds(60)
                                      + c.livenessProbe.withPeriodSeconds(15)
                                      + c.livenessProbe.withTimeoutSeconds(5)
                                    else {}),
                               ],
                               { 'app.kubernetes.io/name': 'immich-postgres' })
                         + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                         + d.spec.template.spec.withInitContainers([
                           c.new('init-pg-config', $._version.ubuntu.image)
                           + c.withCommand(['/bin/sh', '-c'])
                           + c.withArgs(['cp /config/postgresql.override.conf /etc/postgresql/postgresql.override.conf'])
                           + c.securityContext.withAllowPrivilegeEscalation(false)
                           + c.securityContext.withReadOnlyRootFilesystem(true)
                           + c.securityContext.capabilities.withDrop('all')
                           + c.withVolumeMounts([
                             v1.volumeMount.new('etc-postgresql', '/etc/postgresql', false),
                             v1.volumeMount.new('immich-postgres-config', '/config', true),
                           ]),
                         ])
                         + d.spec.template.spec.withVolumes([
                           v1.volume.fromConfigMap('immich-postgres-config', 'immich-postgres-config'),
                           v1.volume.fromPersistentVolumeClaim('immich-postgres', 'immich-postgres'),
                           v1.volume.fromEmptyDir('etc-postgresql', emptyDir={ sizeLimit: '1M' }),
                           v1.volume.fromEmptyDir('var-run-postgresql', emptyDir={ sizeLimit: '1M' }),
                         ])
                         + d.spec.strategy.withType('Recreate')
                         + d.metadata.withNamespace('self-hosted')
                         + d.spec.template.spec.withTerminationGracePeriodSeconds(20),
  },
}
