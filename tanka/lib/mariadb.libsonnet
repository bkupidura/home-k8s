{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  prometheus+: {
    rules+:: [
      {
        name: 'mariadb',
        rules: [
          {
            alert: 'MysqlWrongBufferPoolUsage',
            expr: 'delta(mysql_global_status_innodb_buffer_pool_reads[5m]) / delta(mysql_global_status_innodb_buffer_pool_read_requests[5m]) > 0.03',
            'for': '15m',
            labels: { service: 'mysql', severity: 'warning' },
            annotations: {
              summary: 'Mysql wrong innodb buffer pool reads, check https://mariadb.com/kb/en/innodb-buffer-pool/#innodb_buffer_pool_size',
            },
          },
          {
            alert: 'MysqlDown',
            expr: 'mysql_up == 0',
            'for': '1m',
            labels: { service: 'mysql', severity: 'critical' },
            annotations: {
              summary: 'Mysql server is down',
            },
          },
          {
            alert: 'MysqlTooManyConnections',
            expr: 'max_over_time(mysql_global_status_threads_connected[5m]) / mysql_global_variables_max_connections > 0.8',
            'for': '5m',
            labels: { service: 'mysql', severity: 'warning' },
            annotations: {
              summary: 'Mysql server is using more than {{ $value | humanizePercentage }} of all available connections',
            },
          },
          {
            alert: 'MysqlSlowQueries',
            expr: 'increase(mysql_global_status_slow_queries[5m]) > 0',
            'for': '10m',
            labels: { service: 'mysql', severity: 'warning' },
            annotations: {
              summary: 'Slow queries observed on Mysql',
            },
          },
          {
            alert: 'MysqlInnodbLogWaits',
            expr: 'rate(mysql_global_status_innodb_log_waits[15m]) > 10',
            'for': '2m',
            labels: { service: 'mysql', severity: 'warning' },
            annotations: {
              summary: 'Mysql InnoDB log waits',
            },
          },
          {
            alert: 'MysqlNoFreePages',
            expr: 'delta(mysql_global_status_innodb_buffer_pool_wait_free[5m]) / 300 > 2',
            'for': '5m',
            labels: { service: 'mysql', severity: 'warning' },
            annotations: {
              summary: 'No free pages in buffer pool',
            },
          },
        ],
      },
    ],
  },
  mariadb: {
    pvc: p.new('mariadb')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '8Gi' }),
    service: s.new('mariadb', { 'app.kubernetes.io/name': 'mariadb' }, [v1.servicePort.withPort(3306) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('mysql')])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'mariadb' }),
    cronjob_backup: $._custom.cronjob_backup.new('mariadb',
                                                 'home-infra',
                                                 '40 03 * * *',
                                                 [
                                                   '/bin/sh',
                                                   '-ec',
                                                   std.join('\n',
                                                            [
                                                              'apk add mysql-client',
                                                              'mkdir /dump',
                                                              'cd /dump',
                                                              std.format('mysqldump --all-databases --host=mariadb.home-infra --user=root --password="%s" --result-file=dump-all.sql', std.extVar('secrets').mariadb.password),
                                                              std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default),
                                                            ]),
                                                 ],
                                                 'mariadb'),
    cronjob_restore: $._custom.cronjob_restore.new('mariadb',
                                                   'home-infra',
                                                   [
                                                     '/bin/sh',
                                                     '-ec',
                                                     std.join('\n',
                                                              [
                                                                'apk add mysql-client',
                                                                'mkdir /dump',
                                                                'cd /dump',
                                                                std.format('restic --repo "%s" --verbose restore latest --host mariadb --target .', std.extVar('secrets').restic.repo.default),
                                                                std.format('mysql --host=mariadb.home-infra --user=root --password="%s" < dump-all.sql', std.extVar('secrets').mariadb.password),
                                                              ]),
                                                   ],
                                                   'mariadb')
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                       $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                       + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['mariadb'] }
                       )
                     ),
    init: v1.configMap.new('mariadb-init', {
            'init.sql': std.strReplace(|||
              CREATE DATABASE homeassistant CHARACTER SET utf8mb4;
              CREATE USER 'homeassistant'@'!!' IDENTIFIED BY '%(homeassistant_password)s';
              GRANT ALL PRIVILEGES ON homeassistant.* TO 'homeassistant'@'!!';
              FLUSH PRIVILEGES;
            ||| % std.extVar('secrets').mariadb.init_script, '!!', '%'),
          })
          + v1.configMap.metadata.withNamespace('home-infra'),
    config: v1.configMap.new('mariadb-config', {
              'my.cnf': |||
                [mysqld]
                skip-name-resolve
                explicit_defaults_for_timestamp
                port=3306
                bind-address=0.0.0.0
                datadir=/var/lib/mysql/data
                character-set-server=UTF8
                collation-server=utf8_general_ci
                max_allowed_packet=1M
                key_buffer_size=10M
                max_connections=64
                innodb_buffer_pool_size=128M
                [client]
                port=3306
                default-character-set=UTF8
                [mysqldump]
                max_allowed_packet=16M
                [manager]
                port=3306
              |||,
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('mariadb',
                      1,
                      [
                        c.new('mariadb', $._version.mariadb.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(3306, 'mysql'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          LD_PRELOAD: '/usr/lib/x86_64-linux-gnu/libjemalloc.so.2',
                          MARIADB_ROOT_PASSWORD: std.extVar('secrets').mariadb.password,
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('mariadb-init', '/docker-entrypoint-initdb.d/', true),
                          v1.volumeMount.new('mariadb-config', '/etc/mysql/conf.d/', true),
                          v1.volumeMount.new('mariadb-data', '/var/lib/mysql', false),
                        ])
                        + c.resources.withRequests({ cpu: '200m', memory: '386Mi' })
                        + c.resources.withLimits({ cpu: '200m', memory: '386Mi' })
                        + c.readinessProbe.exec.withCommand([
                          '/bin/bash',
                          '-ec',
                          std.format('/usr/bin/mysqladmin status -uroot -p"%s"', std.extVar('secrets').mariadb.password),
                        ])
                        + c.readinessProbe.withInitialDelaySeconds(20)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.exec.withCommand([
                          '/bin/bash',
                          '-ec',
                          std.format('/usr/bin/mysqladmin status -uroot -p"%s"', std.extVar('secrets').mariadb.password),
                        ])
                        + c.livenessProbe.withInitialDelaySeconds(90)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(2),
                        c.new('metrics', $._version.mariadb.metrics)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(9104, 'metrics'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          DATA_SOURCE_NAME: std.format('root:%s@(localhost:3306)/', std.extVar('secrets').mariadb.password),
                        })
                        + c.readinessProbe.httpGet.withPath('/metrics')
                        + c.readinessProbe.httpGet.withPort('metrics')
                        + c.readinessProbe.withInitialDelaySeconds(20)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/metrics')
                        + c.livenessProbe.httpGet.withPort('metrics')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'mariadb' })
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromConfigMap('mariadb-init', 'mariadb-init'),
                  v1.volume.fromConfigMap('mariadb-config', 'mariadb-config'),
                  v1.volume.fromPersistentVolumeClaim('mariadb-data', 'mariadb'),
                ])
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(10)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9104',
                }),
  },
}
