{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'valkey',
        rules: [
          {
            alert: 'ValkeyDown',
            expr: 'redis_up == 0',
            labels: { service: 'redis', severity: 'critical' },
            annotations: {
              summary: 'Redis down for {{ $labels.pod }}',
            },
          },
          {
            alert: 'ValkeyAOFEnabled',
            expr: 'redis_aof_enabled != 1',
            labels: { service: 'redis', severity: 'critical' },
            annotations: {
              summary: 'Redis AOF is disabled on {{ $labels.pod }}',
            },
          },
          {
            alert: 'ValkeyRDBMissing',
            expr: 'time() - redis_rdb_last_save_timestamp_seconds > 60 * 10',
            labels: { service: 'redis', severity: 'critical' },
            annotations: {
              summary: 'Redis RDB not executed in last 10 minutes for {{ $labels.pod }}',
            },
          },
          {
            alert: 'ValkeyCommandFailed',
            expr: 'delta(redis_commands_failed_calls_total{cmd=~"^(get|set|del|incrby|publish|psubscribe|auth)$"}[5m]) > 0',
            labels: { service: 'redis', severity: 'warning' },
            annotations: {
              summary: 'Observed failed {{ $labels.cmd }} requests on {{ $labels.pod }}',
            },
          },
          {
            alert: 'ValkeyKeysDecrease',
            expr: 'avg by (app_kubernetes_io_name, db) (avg_over_time(redis_db_keys[10m])) < avg by (app_kubernetes_io_name, db) (avg_over_time(redis_db_keys[10m] offset 15m)) * 0.7',
            labels: { service: 'redis', severity: 'warning' },
            annotations: {
              summary: 'Observed decrease in number of keys on {{ $labels.app_kubernetes_io_name }} for {{ $labels.db }}',
            },
          },
        ],
      },
    ],
  },
  valkey: {
    restore:: $._config.restore,
    pvc: p.new('valkey')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '512Mi' }),
    cronjob_backup: $._custom.cronjob.new('valkey-backup',
                                          'home-infra',
                                          '20 03,11,19 * * *',
                                          [
                                            c.new('backup', $._version.restic.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('ssh', '/root/.ssh', false),
                                              v1.volumeMount.new('valkey-data', '/data', false),
                                            ])
                                            + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'set -eo pipefail',
                                                'apk add valkey-cli',
                                                'cd /data',
                                                std.format('export REDISCLI_AUTH="%s"', std.extVar('secrets').valkey.backup.password),
                                                'export now=$(date +%d-%m-%YT%H:%M:%S)',
                                                'mkdir -p backups/backup-${now}',
                                                'echo dumping all keys',
                                                'valkey-cli -h valkey.home-infra --scan | while read key; do',
                                                'export encoded_key=$(echo -n ${key} | sha1sum | cut -f1 -d" ")',
                                                'valkey-cli -h valkey.home-infra --raw dump "${key}" |head -c -1 > backups/backup-${now}/${encoded_key}',
                                                'echo "$key:$encoded_key" >> backups/backup-${now}/key_index; done',
                                                'ls backups/backup-${now}',
                                                std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection),
                                                'find backups/ -mindepth 1 -type d -mtime +6 -iname backup-\\* -exec rm -fr {} +',
                                              ]),
                                            ]),
                                          ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('valkey')
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                      v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                      v1.volume.fromPersistentVolumeClaim('valkey-data', 'valkey'),
                    ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                      v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                      + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                        { key: 'app.kubernetes.io/name', operator: 'In', values: ['valkey'] }
                      )
                    ),
    cronjob_restore: $._custom.cronjob_restore.new('valkey', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'valkey'),
    service: s.new('valkey',
                   { 'app.kubernetes.io/name': 'valkey' },
                   [
                     v1.servicePort.withPort(6379) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('valkey'),
                   ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'valkey' }),
    config: v1.configMap.new('valkey-config', {
              'valkey.conf': |||
                port 6379
                loglevel verbose
                protected-mode no
                dir /data
                save 360 1 60 10
                appendfsync everysec
                appendonly yes
                %(acls)s
              ||| % { acls: std.join('\n', std.extVar('secrets').valkey.acl) },
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('valkey',
                      if $.valkey.restore then 0 else 1,
                      [
                        c.new('valkey', $._version.valkey.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withCommand([
                          'valkey-server',
                          '/config/valkey.conf',
                        ])
                        + c.withPorts([
                          v1.containerPort.newNamed(6379, 'valkey'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '30M', cpu: '75m' })
                        + c.resources.withLimits({ memory: '100M', cpu: '150m' })
                        + c.readinessProbe.tcpSocket.withPort('valkey')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('valkey')
                        + c.livenessProbe.withInitialDelaySeconds(10)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1),
                        c.new('metrics', $._version.valkey.metrics)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(9121, 'metrics'))
                        + c.withEnvMap({
                          REDIS_ADDR: 'redis://localhost:6379',
                          REDIS_USER: 'exporter',
                          REDIS_PASSWORD: std.extVar('secrets').valkey.exporter.password,
                          REDIS_EXPORTER_LOG_FORMAT: 'json',
                          REDIS_EXPORTER_INCL_CONFIG_METRICS: 'false',
                          REDIS_EXPORTER_INCL_SYSTEM_METRICS: 'false',
                          REDIS_EXPORTER_STREAMS_EXCLUDE_CONSUMER_METRICS: 'true',
                          REDIS_EXPORTER_EXCLUDE_LATENCY_HISTOGRAM_METRICS: 'true',
                          REDIS_EXPORTER_DEBUG: 'false',
                        })
                        + c.resources.withRequests({ memory: '10Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '24Mi', cpu: '100m' })
                        + c.readinessProbe.httpGet.withPath('/metrics')
                        + c.readinessProbe.httpGet.withPort('metrics')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/metrics')
                        + c.livenessProbe.httpGet.withPort('metrics')
                        + c.livenessProbe.withInitialDelaySeconds(15)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'valkey' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.pvcVolumeMount('valkey', '/data', false, {})
                + d.configVolumeMount('valkey-config', '/config/', {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9121',
                }),
  },
}
