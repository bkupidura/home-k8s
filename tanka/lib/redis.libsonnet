{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'redis',
        rules: [
          {
            alert: 'RedisAOFEnabled',
            expr: 'redis_aof_enabled != 1',
            labels: { service: 'redis', severity: 'critical' },
            annotations: {
              summary: 'Redis AOF is disabled on {{ $labels.pod }}',
            },
          },
          {
            alert: 'RedisCommandFailed',
            expr: 'delta(redis_commands_failed_calls_total{cmd=~"^(get|set|del|incrby|publish|psubscribe|auth)$"}[5m]) > 0',
            labels: { service: 'redis', severity: 'warning' },
            annotations: {
              summary: 'Observed failed {{ $labels.cmd }} requests on {{ $labels.pod }}',
            },
          },
          {
            alert: 'RedisClientDisconnect',
            expr: 'avg_over_time(redis_connected_clients[5m]) * 1.2 < avg_over_time(redis_connected_clients[5m] offset 10m)',
            labels: { service: 'redis', severity: 'warning' },
            annotations: {
              summary: 'Observed client disconects on {{ $labels.pod }}',
            },
          },
          {
            alert: 'RedisKeysDecrease',
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
  redis: {
    restore:: $._config.restore,
    pvc: p.new('redis')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '512Mi' }),
    cronjob_backup: $._custom.cronjob_backup.new('redis', 'home-infra', '25 05 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'redis'),
    cronjob_restore: $._custom.cronjob_restore.new('redis', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host redis --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'redis'),
    service: s.new('redis',
                   { 'app.kubernetes.io/name': 'redis' },
                   [
                     v1.servicePort.withPort(6379) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('redis'),
                   ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'redis' })
             + s.metadata.withAnnotations({ 'metallb.universe.tf/loadBalancerIPs': $._config.vip.redis })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    config: v1.configMap.new('redis-config', {
              'redis.conf': |||
                port 6379
                loglevel notice
                protected-mode no
                dir /data
                save 360 1 60 10
                appendfsync everysec
                appendonly yes
                %(acls)s
              ||| % { acls: std.join('\n', std.extVar('secrets').redis.acl) },
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('redis',
                      if $.redis.restore then 0 else 1,
                      [
                        c.new('redis', $._version.redis.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withCommand([
                          'redis-server',
                          '/config/redis.conf',
                        ])
                        + c.withPorts([
                          v1.containerPort.newNamed(6379, 'redis'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '16Mi', cpu: '20m' })
                        + c.resources.withLimits({ memory: '64Mi', cpu: '40m' })
                        + c.readinessProbe.tcpSocket.withPort('redis')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('redis')
                        + c.livenessProbe.withInitialDelaySeconds(10)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1),
                        c.new('metrics', $._version.redis.metrics)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(9121, 'metrics'))
                        + c.withEnvMap({
                          REDIS_ADDR: 'redis://localhost:6379',
                          REDIS_USER: 'exporter',
                          REDIS_PASSWORD: std.extVar('secrets').redis.exporter.password,
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
                      { 'app.kubernetes.io/name': 'redis' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.pvcVolumeMount('redis', '/data', false, {})
                + d.configVolumeMount('redis-config', '/config/', {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9121',
                }),
  },
}
