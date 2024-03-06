{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  logging+: {
    rules+:: [
      {
        name: 'fluentbit',
        interval: '1m',
        rules: [
          {
            record: 'fluentbit:unknown_parser:5m',
            expr: 'count_over_time({kubernetes_container_name="fluent-bit"} |~ "annotation parser \'.*\' not found"[5m])',
          },
        ],
      },
    ],
  },
  monitoring+: {
    rules+:: [
      {
        name: 'fluentbit',
        rules: [
          {
            alert: 'UnknownParser',
            expr: 'fluentbit:unknown_parser:5m > 0',
            labels: { service: 'fluentbit', severity: 'warning' },
            annotations: {
              summary: 'Unknown fluentbit parsed configured',
            },
          },
        ],
      },
    ],
  },
  loki: {
    [if $.logging.parsers != null then 'parsers']:: [
      $.logging.parsers[parser]
      for parser in std.objectFields($.logging.parsers)
    ],
    config_rules: v1.configMap.new('loki-rules', {
                    'rules.yaml': std.manifestYamlDoc({
                      groups: std.prune($.logging.rules),
                    }),
                  })
                  + v1.configMap.metadata.withNamespace('monitoring'),
    helm: $._custom.helm.new('loki', 'https://grafana.github.io/helm-charts', $._version.loki.server, 'monitoring', {
      loki: {
        commonConfig: {
          replication_factor: 1,
        },
        storage: {
          type: 'filesystem',
        },
        auth_enabled: false,
        rulerConfig: {
          wal: {
            dir: '/var/loki/ruler-wal',
          },
          storage: {
            type: 'local',
            'local': {
              directory: '/etc/loki/rules',
            },
          },
          [if std.objectHas($, 'victoria_metrics') then 'remote_write']: {
            enabled: true,
            client: {
              url: 'http://victoria-metrics-single-server.monitoring:8428/api/v1/write',
            },
          },
        },
      },
      test: {
        enabled: false,
      },
      gateway: {
        enabled: false,
      },
      monitoring: {
        selfMonitoring: {
          enabled: false,
          grafanaAgent: {
            installOperator: false,
          },
        },
        lokiCanary: {
          enabled: false,
        },
      },
      singleBinary: {
        replicas: 1,
        persistence: {
          enabled: true,
          storageClass: std.get($.storage.class_without_snapshot.metadata, 'name'),
          size: '20Gi',
        },
        podAnnotations: {
          'prometheus.io/port': '3100',
        },
        resources: {
          requests: { memory: '128Mi' },
          limits: { memory: '256Mi' },
        },
        extraVolumes: [
          {
            name: 'custom-rules',
            configMap: {
              name: 'loki-rules',
            },
          },
        ],
        extraVolumeMounts: [
          {
            name: 'custom-rules',
            mountPath: '/etc/loki/rules',
          },
        ],
      },
    }),
    helm_fluentbit: $._custom.helm.new('fluent-bit', 'https://fluent.github.io/helm-charts', $._version.loki.fluentbit, 'monitoring', {
      config: {
        filters: |||
          [FILTER]
              name kubernetes
              match kube.*
              merge_log on
              merge_log_key parsed
              keep_log off
              annotations off
              k8s-logging.parser on
              k8s-logging.exclude on
        |||,
        outputs: |||
          [OUTPUT]
              name loki
              match kube.*
              host loki.monitoring
              port 3100
              labels job=fluentbit, tag=kube, $kubernetes['container_name'], $kubernetes['pod_name']
              auto_kubernetes_labels on
          [OUTPUT]
              name loki
              match host.*
              host loki.monitoring
              port 3100
              labels job=fluentbit, tag=host
        |||,
        [if std.length($.loki.parsers) > 0 then 'customParsers']: std.join('\n', $.loki.parsers),
      },
      podAnnotations: {
        'prometheus.io/port': '2020',
        'prometheus.io/scrape': 'true',
        'prometheus.io/path': '/api/v1/metrics/prometheus',
      },
      resources: {
        limits: { memory: '64Mi', cpu: '50m' },
      },
    }),
  },
}
