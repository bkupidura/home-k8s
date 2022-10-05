{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  monitoring+: {
    rules+:: [
      {
        name: 'prometheus',
        rules: [
          {
            alert: 'PrometheusInstanceDown',
            expr: 'up == 0',
            'for': '5m',
            labels: { service: 'prometheus', severity: 'warning' },
            annotations: {
              summary: 'Prometheus instance {{ $labels.instance }} is down for job {{ $labels.job }}',
            },
          },
          {
            alert: 'PrometheusBadConfig',
            expr: 'max_over_time(prometheus_config_last_reload_successful[5m]) == 0',
            'for': '10m',
            labels: { service: 'prometheus', severity: 'critical' },
            annotations: {
              summary: 'Failed Prometheus configuration reload',
            },
          },
          {
            alert: 'PrometheusErrorSendingAlertsToAnyAlertmanager',
            expr: 'min without(alertmanager) (rate(prometheus_notifications_errors_total[5m]) / rate(prometheus_notifications_sent_total[5m])) * 100 > 3',
            'for': '15m',
            labels: { service: 'prometheus', severity: 'critical' },
            annotations: {
              summary: 'Prometheus encounters more than 3% errors sending alerts to any Alertmanager',
            },
          },
          {
            alert: 'PrometheusNotIngestingSamples',
            expr: 'rate(prometheus_tsdb_head_samples_appended_total[5m]) <= 0',
            'for': '10m',
            labels: { service: 'prometheus', severity: 'warning' },
            annotations: {
              summary: 'Prometheus is not ingesting samples',
            },
          },
          {
            alert: 'PrometheusRuleFailures',
            expr: 'increase(prometheus_rule_evaluation_failures_total[5m]) > 0',
            'for': '15m',
            labels: { service: 'prometheus', severity: 'critical' },
            annotations: {
              summary: 'Prometheus is failing rule evaluations',
            },
          },
        ],
      },
    ],
  },
  prometheus: {
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        rules: group.rules,
      }
      for group in $.monitoring.rules
    ],
    extra_scrape_rendered:: [
      $.monitoring.extra_scrape[extra_scrape]
      for extra_scrape in std.objectFields($.monitoring.extra_scrape)
    ],
    pvc_prometheus: p.new('prometheus-server')
                    + p.metadata.withNamespace('monitoring')
                    + p.spec.withAccessModes(['ReadWriteOnce'])
                    + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
                    + p.spec.resources.withRequests({ storage: '10Gi' }),
    pvc_alertmanager: p.new('alertmanager')
                      + p.metadata.withNamespace('monitoring')
                      + p.spec.withAccessModes(['ReadWriteOnce'])
                      + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
                      + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route_prometheus: $._custom.ingress_route.new('prometheus', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`prometheus.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'prometheus-server', port: 80, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    ingress_route_alertmanager: $._custom.ingress_route.new('alertmanager', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`alertmanager.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'prometheus-alertmanager', port: 80, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    helm: $._custom.helm.new('prometheus', 'https://prometheus-community.github.io/helm-charts', $._version.prometheus.chart, 'monitoring', {
      configmapReload: {
        alertmanager: {
          resources: {
            requests: { memory: '16Mi' },
            limits: { memory: '32Mi' },
          },
        },
        prometheus: {
          resources: {
            requests: { memory: '16Mi' },
            limits: { memory: '32Mi' },
          },
        },
      },
      extraEnv: { TZ: $._config.tz },
      alertmanager: {
        resources: {
          requests: { memory: '32Mi' },
          limits: { memory: '64Mi' },
        },
        baseURL: std.format('https://alertmanager.%s', std.extVar('secrets').domain),
        podLabels: { 'app.kubernetes.io/name': 'alertmanager' },
        strategy: { type: 'Recreate' },
        enabled: true,
        persistentVolume: { existingClaim: 'alertmanager' },
      },
      alertmanagerFiles: {
        'alertmanager.yml': {
          global: {},
          receivers: [
            {
              name: 'default-receiver',
              email_configs: [
                {
                  auth_password: std.extVar('secrets').smtp.password,
                  auth_username: std.extVar('secrets').smtp.username,
                  from: std.format('alertmanager@%s', std.extVar('secrets').domain),
                  headers: {
                    subject: |||
                      [{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}]{{ range .Alerts }} {{ .Labels.alertname }}/{{ .Labels.severity | toUpper }}/{{ .Status }}{{ end }}'
                    |||,
                  },
                  require_tls: true,
                  send_resolved: true,
                  smarthost: std.format('%s:%d', [std.extVar('secrets').smtp.server, std.extVar('secrets').smtp.port]),
                  to: std.extVar('secrets').mail,
                },
              ],
            },
          ],
          route: {
            group_wait: '10s',
            group_interval: '5m',
            group_by: ['service'],
            receiver: 'default-receiver',
            repeat_interval: '24h',
          },
          inhibit_rules: [
            { equal: ['service'], source_match: { severity: 'critical' }, target_match: { severity: 'warning' } },
            { equal: ['service'], source_match: { severity: 'warning' }, target_match: { severity: 'info' } },
          ],
        },
      },
      pushgateway: { enabled: false },
      kubeStateMetrics: { enabled: true },
      'kube-state-metrics': {
        resources: {
          requests: { memory: '64Mi' },
          limits: { memory: '96Mi' },
        },
      },
      nodeExporter: {
        enabled: true,
        resources: {
          requests: { memory: '32Mi' },
          limits: { memory: '64Mi' },
        },
      },
      server: {
        enabled: true,
        resources: {
          requests: { memory: '2560Mi' },
          limits: { memory: '2560Mi' },
        },
        global: { external_labels: { source: 'prometheus' } },
        baseURL: std.format('https://prometheus.%s', std.extVar('secrets').domain),
        podLabels: { 'app.kubernetes.io/name': 'prometheus' },
        strategy: { type: 'Recreate' },
        persistentVolume: { existingClaim: 'prometheus-server' },
      },
      serverFiles: {
        'alerting_rules.yml': {
          groups: std.prune($.prometheus.rules_rendered),
        },
      },
      extraScrapeConfigs: std.manifestYamlDoc($.prometheus.extra_scrape_rendered),
    }),
  },
}
