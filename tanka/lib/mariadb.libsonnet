{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'mariadb',
        rules: [
          {
            alert: 'MysqlWrongBufferPoolUsage',
            expr: 'delta(mysql_global_status_innodb_buffer_pool_reads[5m]) / delta(mysql_global_status_innodb_buffer_pool_read_requests[5m]) > 0.03',
            'for': '60m',
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
            expr: 'increase(mysql_global_status_slow_queries[5m]) > 5',
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
    update:: $._config.update,
    restore:: $._config.restore,
    pvc: p.new('mariadb')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '5Gi' }),
    service: s.new('mariadb', { 'app.kubernetes.io/name': 'mariadb' }, [v1.servicePort.withPort(3306) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('mysql')])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'mariadb' }),
    cronjob_backup: $._custom.cronjob.new('mariadb-backup',
                                          'home-infra',
                                          '40 03,15 * * *',
                                          [
                                            c.new('backup', $._version.mariadb.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('ssh', '/root/.ssh', false),
                                              v1.volumeMount.new('mariadb-config', '/etc/mysql/conf.d/', true),
                                              v1.volumeMount.new('mariadb-data', '/var/lib/mysql', false),
                                            ])
                                            + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'apt update || true',
                                                'apt install -y restic openssh-client',
                                                'mkdir /dump',
                                                'cd /dump',
                                                std.format('mariabackup --backup --target-dir=/dump --host=mariadb.home-infra --user=root --password="%s"', std.extVar('secrets').mariadb.password),
                                                std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection),
                                              ]),
                                            ]),
                                          ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('mariadb')
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                      v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                      v1.volume.fromPersistentVolumeClaim('mariadb-data', 'mariadb'),
                      v1.volume.fromConfigMap('mariadb-config', 'mariadb-config'),
                    ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                      v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                      + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                        { key: 'app.kubernetes.io/name', operator: 'In', values: ['mariadb'] }
                      )
                    ),
    cronjob_restore: $._custom.cronjob.new('mariadb-restore',
                                           'home-infra',
                                           '0 0 * * *',
                                           [
                                             c.new('restore', $._version.mariadb.image)
                                             + c.withVolumeMounts([
                                               v1.volumeMount.new('ssh', '/root/.ssh', false),
                                               v1.volumeMount.new('mariadb-config', '/etc/mysql/conf.d/', true),
                                               v1.volumeMount.new('mariadb-data', '/var/lib/mysql', false),
                                             ])
                                             + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                             + c.withEnvMap({
                                               RESTIC_HOST: 'mariadb',
                                             })
                                             + c.withCommand([
                                               '/bin/sh',
                                               '-ec',
                                               std.join('\n', [
                                                 'apt update || true',
                                                 'apt install -y restic openssh-client',
                                                 'mkdir /dump',
                                                 'cd /dump',
                                                 std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection),
                                                 'mariabackup --prepare --target-dir=/dump',
                                                 'mariabackup --copy-back --target-dir=/dump',
                                                 'chown -R mysql:mysql /var/lib/mysql/data',
                                               ]),
                                             ]),
                                           ])
                     + $.k.batch.v1.cronJob.spec.withSuspend(true)
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('mariadb')
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                       v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                       v1.volume.fromPersistentVolumeClaim('mariadb-data', 'mariadb'),
                       v1.volume.fromConfigMap('mariadb-config', 'mariadb-config'),
                     ]),
    init: v1.configMap.new('mariadb-init', {
            'init.sql': std.strReplace(|||
              CREATE DATABASE homeassistant CHARACTER SET utf8mb4;
              CREATE USER 'homeassistant'@'!!' IDENTIFIED BY '%(homeassistant_password)s';
              GRANT ALL PRIVILEGES ON homeassistant.* TO 'homeassistant'@'!!';
              CREATE DATABASE nextcloud CHARACTER SET utf8mb4;
              CREATE USER 'nextcloud'@'!!' IDENTIFIED BY '%(nextcloud_password)s';
              GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'!!';
              FLUSH PRIVILEGES;
              CREATE DATABASE freshrss CHARACTER SET utf8mb4;
              CREATE USER 'freshrss'@'!!' IDENTIFIED BY '%(freshrss_password)s';
              GRANT ALL PRIVILEGES ON freshrss.* TO 'freshrss'@'!!';
              FLUSH PRIVILEGES;
              CREATE DATABASE authelia CHARACTER SET utf8mb4;
              CREATE USER 'authelia'@'!!' IDENTIFIED BY '%(authelia_password)s';
              GRANT ALL PRIVILEGES ON authelia.* TO 'authelia'@'!!';
              FLUSH PRIVILEGES;
              CREATE DATABASE grafana CHARACTER SET utf8mb4;
              CREATE USER 'grafana'@'!!' IDENTIFIED BY '%(grafana_password)s';
              GRANT ALL PRIVILEGES ON grafana.* TO 'grafana'@'!!';
              FLUSH PRIVILEGES;
              CREATE DATABASE paperless CHARACTER SET utf8mb4;
              CREATE USER 'paperless'@'!!' IDENTIFIED BY '%(paperless_password)s';
              GRANT ALL PRIVILEGES ON paperless.* TO 'paperless'@'!!';
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
                max_connections=128
                myisam_recover_options = FORCE
                myisam_sort_buffer_size = 8M
                net_buffer_length = 16K
                read_buffer_size = 256K
                read_rnd_buffer_size = 512K
                sort_buffer_size = 512K
                join_buffer_size = 128K
                table_open_cache = 64
                thread_cache_size = 8
                thread_stack = 192K
                tmp_table_size = 16M

                query_cache_limit = 1M
                query_cache_size = 0M
                query_cache_type = 0

                innodb_buffer_pool_size=128M
                innodb_log_buffer_size = 8M
                innodb_log_file_size = 48M
                max_binlog_size = 96M

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
    config_exporter: v1.configMap.new('mariadb-exporter-config', {
                       'my.cnf': |||
                         [client]
                         user = root
                         password = %(password)s
                       ||| % { password: std.extVar('secrets').mariadb.password },
                     })
                     + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('mariadb',
                      if $.mariadb.restore then 0 else 1,
                      [
                        c.new('mariadb', $._version.mariadb.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(3306, 'mysql'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          LD_PRELOAD: '/usr/lib/x86_64-linux-gnu/libjemalloc.so.2',
                          MARIADB_ROOT_PASSWORD: std.extVar('secrets').mariadb.password,
                          MARIADB_AUTO_UPGRADE: '1',
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('mariadb-init', '/docker-entrypoint-initdb.d/', true),
                          v1.volumeMount.new('mariadb-config', '/etc/mysql/conf.d/', true),
                          v1.volumeMount.new('mariadb-data', '/var/lib/mysql', false),
                        ])
                        + (if $.mariadb.update == false then
                             c.resources.withRequests({ cpu: '300m', memory: '768Mi' })
                             + c.resources.withLimits({ cpu: '300m', memory: '768Mi' })
                             + c.readinessProbe.exec.withCommand([
                               '/bin/bash',
                               '-ec',
                               std.format('/usr/bin/mariadb-admin status -uroot -p"%s"', std.extVar('secrets').mariadb.password),
                             ])
                             + c.readinessProbe.withInitialDelaySeconds(20)
                             + c.readinessProbe.withPeriodSeconds(15)
                             + c.readinessProbe.withTimeoutSeconds(2)
                             + c.livenessProbe.exec.withCommand([
                               '/bin/bash',
                               '-ec',
                               std.format('/usr/bin/mariadb-admin status -uroot -p"%s"', std.extVar('secrets').mariadb.password),
                             ])
                             + c.livenessProbe.withInitialDelaySeconds(90)
                             + c.livenessProbe.withPeriodSeconds(15)
                             + c.livenessProbe.withTimeoutSeconds(2)
                           else {}),
                        c.new('metrics', $._version.mariadb.metrics)
                        + c.withArgs([
                          '--config.my-cnf',
                          '/config/my.cnf',
                          '--collect.global_status',
                          '--collect.global_variables',
                          '--no-collect.info_schema.processlist',
                          '--no-collect.info_schema.innodb_cmp',
                          '--no-collect.info_schema.innodb_cmpmem',
                          '--no-collect.info_schema.query_response_time',
                          '--no-collect.slave_status',
                        ])
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(9104, 'metrics'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('mariadb-exporter-config', '/config/', true),
                        ])
                        + (if $.mariadb.update == false then
                             c.resources.withRequests({ cpu: '150m', memory: '15Mi' })
                             + c.resources.withLimits({ cpu: '300m', memory: '30Mi' })
                             + c.readinessProbe.httpGet.withPath('/metrics')
                             + c.readinessProbe.httpGet.withPort('metrics')
                             + c.readinessProbe.withInitialDelaySeconds(20)
                             + c.readinessProbe.withPeriodSeconds(10)
                             + c.readinessProbe.withTimeoutSeconds(2)
                             + c.livenessProbe.httpGet.withPath('/metrics')
                             + c.livenessProbe.httpGet.withPort('metrics')
                             + c.livenessProbe.withInitialDelaySeconds(30)
                             + c.livenessProbe.withPeriodSeconds(10)
                             + c.livenessProbe.withTimeoutSeconds(2)
                           else {}),
                      ],
                      { 'app.kubernetes.io/name': 'mariadb' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromConfigMap('mariadb-init', 'mariadb-init'),
                  v1.volume.fromConfigMap('mariadb-config', 'mariadb-config'),
                  v1.volume.fromConfigMap('mariadb-exporter-config', 'mariadb-exporter-config'),
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
