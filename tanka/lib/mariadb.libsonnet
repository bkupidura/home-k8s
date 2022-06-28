{
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
                                                 'data-mariadb-0'),
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
                                                   'data-mariadb-0')
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                       $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                       + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['mariadb'] }
                       )
                     ),
    helm: $._custom.helm.new('mariadb', 'https://charts.bitnami.com/bitnami', $._version.mariadb.chart, 'home-infra', {
      architecture: 'standalone',
      image: {
        registry: $._version.mariadb.registry,
        repository: $._version.mariadb.repo,
        tag: $._version.mariadb.tag,
        debug: true,
      },
      auth: {
        rootPassword: std.extVar('secrets').mariadb.password,
        database: '',
      },
      initdbScripts: {
        'init.sql': std.strReplace(|||
          CREATE DATABASE homeassistant CHARACTER SET utf8mb4;
          CREATE USER 'homeassistant'@'!!' IDENTIFIED BY '%(homeassistant_password)s';
          GRANT ALL PRIVILEGES ON homeassistant.* TO 'homeassistant'@'!!';
          FLUSH PRIVILEGES;
        ||| % std.extVar('secrets').mariadb.init_script, '!!', '%'),
      },
      primary: {
        extraEnvVars: [
          { name: 'TZ', value: $._config.tz },
        ],
        persistence: {
          storageClass: 'longhorn-standard',
          accessModes: ['ReadWriteOnce'],
          size: '8Gi',
        },
        resources: {
          requests: { cpu: '200m', memory: '384Mi' },
          limits: { cpu: '200m', memory: '384Mi' },
        },
        livenessProbe: { failureThreshold: 5, timeoutSeconds: 2, periodSeconds: 15 },
        configuration: |||
          [mysqld]
          skip-name-resolve
          explicit_defaults_for_timestamp
          basedir=/opt/bitnami/mariadb
          plugin_dir=/opt/bitnami/mariadb/plugin
          port=3306
          socket=/opt/bitnami/mariadb/tmp/mysql.sock
          tmpdir=/opt/bitnami/mariadb/tmp
          max_allowed_packet=16M
          bind-address=0.0.0.0
          pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
          log-error=/opt/bitnami/mariadb/logs/mysqld.log
          character-set-server=UTF8
          collation-server=utf8_general_ci
          innodb_buffer_pool_size=128M
          innodb_buffer_pool_instances=1
          key_buffer_size=10M
          max_connections=100
          [client]
          port=3306
          socket=/opt/bitnami/mariadb/tmp/mysql.sock
          default-character-set=UTF8
          plugin_dir=/opt/bitnami/mariadb/plugin
          [manager]
          port=3306
          socket=/opt/bitnami/mariadb/tmp/mysql.sock
          pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
        |||,
      },
      metrics: { enabled: true },
    }),
  },
}
