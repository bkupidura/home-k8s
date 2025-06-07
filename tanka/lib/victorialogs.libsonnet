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
            alert: 'FluentbitUnknownParser',
            expr: '_time:5m kubernetes.container_name: "fluent-bit" and contains_all("annotation parser", "not found") | stats count() as log_count | filter log_count :> 0',
            labels: { service: 'fluentbit', severity: 'warning' },
            annotations: {
              summary: 'Unknown fluentbit parsed configured',
            },
          },
        ],
      },
    ],
  },
  fluentbit: {
    [if $.logging.parsers != null then 'parsers']:: [
      $.logging.parsers[parser]
      for parser in std.objectFields($.logging.parsers)
    ],
    helm: $._custom.helm.new('fluent-bit', 'fluent-bit', 'https://fluent.github.io/helm-charts', $._version.fluentbit.chart, 'monitoring', {
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
              name http
              match *
              host victoria-logs-single-server.monitoring
              port 9428
              uri /insert/jsonline?_stream_fields=stream&_msg_field=log&_time_field=date&debug=0
              format json_lines
              json_date_format iso8601
        |||,
        [if std.length($.fluentbit.parsers) > 0 then 'customParsers']: std.join('\n', $.fluentbit.parsers),
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
  victoria_logs: {
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        [if std.get(group, 'interval') != null then 'interval']: group.interval,
        rules: group.rules,
      }
      for group in $.logging.rules
    ],
    pvc_server: p.new('victoria-logs')
                + p.metadata.withNamespace('monitoring')
                + p.spec.withAccessModes(['ReadWriteOnce'])
                + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
                + p.spec.resources.withRequests({ storage: '10Gi' }),
    helm_server: $._custom.helm.new('victoria-logs-single', 'victoria-logs-single', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.logs.chart, 'monitoring', {
      server: {
        enabled: true,
        retentionPeriod: '4w',
        resources: {
          requests: { memory: '300M' },
          limits: { memory: '600M' },
        },
        persistentVolume: {
          enabled: true,
          existingClaim: 'victoria-logs',
        },
      },
    }),
    helm_alert: $._custom.helm.new('victoria-logs-alert', 'victoria-metrics-alert', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.alert.chart, 'monitoring', {
      server: {
        enabled: true,
        resources: {
          requests: { memory: '25Mi' },
          limits: { memory: '50Mi' },
        },
        extraArgs: {
          configCheckInterval: '5m',
          'external.label': 'source=victoria-logs',
          'rule.defaultRuleType': 'vlogs',
        },
        datasource: {
          url: 'http://victoria-logs-single-server.monitoring:9428',
        },
        remote: {
          write: {
            url: 'http://victoria-metrics-single-server.monitoring:8428',
          },
          read: {
            url: 'http://victoria-metrics-single-server.monitoring:8428',
          },
        },
        notifier: {
          alertmanager: {
            url: 'http://alertmanager.monitoring:9093',
          },
        },
        config: {
          alerts: {
            groups: std.prune($.victoria_logs.rules_rendered),
          },
        },
        podAnnotations: {
          'fluentbit.io/parser': 'json',
        },
      },
    }),
  },
}
