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
                + p.spec.resources.withRequests({ storage: '50Gi' }),
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
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
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
    config_postgres: v1.configMap.new('immich-postgres-config', {
                       'postgresql.conf': |||
                         listen_addresses = '*'
                         shared_preload_libraries = 'vectors.so'
                         search_path = '"$user", public, vectors'
                         logging_collector = on
                         max_wal_size = 512MB
                         shared_buffers = 128MB
                         wal_compression = on
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
                                                         std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection),
                                                       ]),
                                                     ]),
                                                   ],
                                                   [
                                                     c.new('pre-backup', $._version.immich.postgres)
                                                     + c.withVolumeMounts([
                                                       v1.volumeMount.new('workdir', '/data', false),
                                                     ])
                                                     + c.withCommand([
                                                       '/bin/sh',
                                                       '-ec',
                                                       std.join('\n', [
                                                         'cd /data',
                                                         std.format('PGPASSWORD="%s" pg_dumpall -U postgres -h immich-postgres.self-hosted -f db-backup-$(date +%%d-%%m-%%YT%%H:%%M:%%S).sql', std.extVar('secrets').immich.postgres.password),
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
                                                      + c.withCommand([
                                                        '/bin/sh',
                                                        '-ec',
                                                        std.join('\n', [
                                                          'cd /data',
                                                          'LATEST=`find . -type f -printf "%T+ %p\n" | sort -r | head  -1 | cut -f2 -d" "`',
                                                          'echo using $LATEST backup',
                                                          std.format('PGPASSWORD="%s" psql -U postgres -h immich-postgres.self-hosted -f $LATEST', std.extVar('secrets').immich.postgres.password),
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
                                                          std.format('restic --repo "%s" --verbose restore latest -H immich-postgres --target .', std.extVar('secrets').restic.repo.default.connection),
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
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'immich-data'),
    cronjob_restore_immich: $._custom.cronjob_restore.new('immich', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'immich-data'),
    deployment_immich: d.new('immich',
                             if $.immich.restore then 0 else 1,
                             [
                               c.new('immich', $._version.immich.image)
                               + c.withImagePullPolicy('IfNotPresent')
                               + c.withPorts([v1.containerPort.newNamed(2283, 'http'), v1.containerPort.newNamed(8081, 'api-metrics'), v1.containerPort.newNamed(8082, 'ms-metrics')])
                               + c.withEnvMap({
                                 TZ: $._config.tz,
                                 DB_URL: std.format('postgresql://postgres:%s@immich-postgres.self-hosted:5432/immich', std.extVar('secrets').immich.postgres.password),
                                 DB_VECTOR_EXTENSION: 'pgvecto.rs',
                                 REDIS_PASSWORD: std.extVar('secrets').immich.valkey.password,
                                 REDIS_HOSTNAME: 'valkey.home-infra',
                                 REDIS_USERNAME: 'immich',
                                 IMMICH_TELEMETRY_INCLUDE: 'all',
                                 IMMICH_PORT: '2283',
                               })
                               + c.withVolumeMounts([
                                 v1.volumeMount.new('dev-dri-renderd128', '/dev/dri/renderD128', false),
                               ])
                               + c.securityContext.withPrivileged(true)
                               + (if $.immich.update == false then
                                    c.resources.withRequests({ cpu: '300m', memory: '500M' })
                                    + c.resources.withLimits({ cpu: '500m', memory: '1G' })
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
                                  else {}),
                             ],
                             { 'app.kubernetes.io/name': 'immich' })
                       + d.spec.template.spec.withVolumes(v1.volume.fromHostPath('dev-dri-renderd128', '/dev/dri/renderD128') + v1.volume.hostPath.withType('CharDevice'))
                       + d.spec.template.spec.withNodeSelector({ video_processing: 'true' })
                       + d.pvcVolumeMount('immich-data', '/usr/src/app/upload', false, {})
                       + d.spec.strategy.withType('Recreate')
                       + d.metadata.withNamespace('self-hosted')
                       + d.spec.template.spec.withTerminationGracePeriodSeconds(10),
    deployment_postgres: d.new('immich-postgres',
                               1,
                               [
                                 c.new('postgres', $._version.immich.postgres)
                                 + c.withArgs([
                                   'postgres',
                                   '-c',
                                   'config_file=/etc/postgresql/postgresql.conf',
                                 ])
                                 + c.withImagePullPolicy('IfNotPresent')
                                 + c.withPorts(v1.containerPort.newNamed(5432, 'postgres'))
                                 + c.withEnvMap({
                                   TZ: $._config.tz,
                                   POSTGRES_INITDB_ARGS: '--data-checksums',
                                   POSTGRES_PASSWORD: std.extVar('secrets').immich.postgres.password,
                                   POSTGRES_USER: 'postgres',
                                   POSTGRES_DB: 'immich',
                                   PGDATA: '/var/lib/postgresql/data/pgdata',
                                 })
                                 + c.withVolumeMounts([
                                   v1.volumeMount.new('immich-postgres-config', '/etc/postgresql', true),
                                   v1.volumeMount.new('immich-postgres', '/var/lib/postgresql/data', false),
                                 ])
                                 + (if $.immich.update == false then
                                      c.resources.withRequests({ cpu: '200m', memory: '200M' })
                                      + c.resources.withLimits({ cpu: '350m', memory: '300M' })
                                      + c.readinessProbe.exec.withCommand([
                                        '/bin/bash',
                                        '-ec',
                                        '/usr/bin/pg_isready || exit 1',
                                      ])
                                      + c.readinessProbe.withInitialDelaySeconds(20)
                                      + c.readinessProbe.withPeriodSeconds(15)
                                      + c.readinessProbe.withTimeoutSeconds(3)
                                      + c.livenessProbe.exec.withCommand([
                                        '/bin/bash',
                                        '-ec',
                                        '/usr/bin/pg_isready || exit 1',
                                        'CHKSUM=`psql -t -A -Upostgres --command="SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database"`',
                                        '[ $CHKSUM -eq 0 ] || exit 2',
                                      ])
                                      + c.livenessProbe.withInitialDelaySeconds(60)
                                      + c.livenessProbe.withPeriodSeconds(15)
                                      + c.livenessProbe.withTimeoutSeconds(5)
                                    else {}),
                               ],
                               { 'app.kubernetes.io/name': 'immich-postgres' })
                         + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                         + d.spec.template.spec.withVolumes([
                           v1.volume.fromConfigMap('immich-postgres-config', 'immich-postgres-config'),
                           v1.volume.fromPersistentVolumeClaim('immich-postgres', 'immich-postgres'),
                         ])
                         + d.spec.strategy.withType('Recreate')
                         + d.metadata.withNamespace('self-hosted')
                         + d.spec.template.spec.withTerminationGracePeriodSeconds(20),
  },
}
