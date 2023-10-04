{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  monitoring+: {
    extra_scrape+:: {
      blackbox_icmp_infra: {
        job_name: 'blackbox-icmp-infra',
        relabel_configs: [
          { source_labels: ['__address__'], target_label: '__param_target'},
          { source_labels: ['__param_target'], target_label: 'instance'},
          { target_label: '__address__', replacement: 'prometheus-blackbox-exporter.monitoring:9115'},
        ],
        metrics_path: '/probe',
        params: {
            module: ['icmp'],
        },
        scrape_interval: '10s',
        static_configs: std.extVar('secrets').monitoring.target.infra,
      },
    },
    rules+:: [
      {
        name: 'victoria-metrics',
        rules: [
          {
            alert: 'InstanceDown',
            expr: 'up == 0',
            'for': '5m',
            labels: { service: 'victoria-metrics', severity: 'warning' },
            annotations: {
              summary: 'Prometheus instance {{ $labels.instance }} is down for job {{ $labels.job }}',
            },
          },
          {
            alert: 'BlackboxExporterProbeFailure',
            expr: '1 - avg_over_time(probe_success[10m]) > 0.25',
            'for': '5m',
            labels: { service: 'blackbox-exporter', severity: 'warning' },
            annotations: {
              summary: 'Blackbox-exporter {{ $labels.name }} is failing for job {{ $labels.job }}',
            },
          },
          {
            alert: 'VMReadOnlyStorage',
            expr: 'vm_storage_is_read_only != 0 ',
            labels: { service: 'victoria-metrics', severity: 'critical' },
            annotations: {
              summary: 'Victoria-metrics {{ $labels.instance }} is not able to write new scrapes',
            },
          },
        ],
      },
    ],
  },
  victoria_metrics: {
    [if $.monitoring.extra_scrape != null then 'extra_scrape_rendered']:: [
      $.monitoring.extra_scrape[extra_scrape]
      for extra_scrape in std.objectFields($.monitoring.extra_scrape)
    ],
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        rules: group.rules,
      }
      for group in $.monitoring.rules
    ],
    pvc_server: p.new('victoria-metrics')
                + p.metadata.withNamespace('monitoring')
                + p.spec.withAccessModes(['ReadWriteOnce'])
                + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
                + p.spec.resources.withRequests({ storage: '35Gi' }),
    ingress_route_alert: $._custom.ingress_route.new('victoria-metrics-alert', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`vm-alert.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'victoria-metrics-alert-server', port: 8880, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    ingress_route_server: $._custom.ingress_route.new('victoria-metrics', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`vm-server.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'victoria-metrics-single-server', port: 8428, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    ingress_route_alertmanager: $._custom.ingress_route.new('alertmanager', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`alertmanager.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'prometheus-alertmanager', port: 9093, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    helm_alert: $._custom.helm.new('victoria-metrics-alert', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.alert.chart, 'monitoring', {
      server: {
        enabled: true,
        resources: {
          requests: { memory: '24Mi' },
          limits: { memory: '24Mi' },
        },
        extraArgs: {
          configCheckInterval: '5m',
          'external.url': std.format('https://vm-alert.%s', std.extVar('secrets').domain),
          'external.label': 'source=victoria-metrics',
        },
        datasource: {
          url: 'http://victoria-metrics-single-server.monitoring:8428',
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
            url: 'http://prometheus-alertmanager.monitoring:9093',
          },
        },
        config: {
          alerts: {
            groups: std.prune($.victoria_metrics.rules_rendered),
          },
        },
      },
    }),
    helm_server: $._custom.helm.new('victoria-metrics-single', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.server.chart, 'monitoring', {
      server: {
        enabled: true,
        extraArgs: {
          'promscrape.suppressDuplicateScrapeTargetErrors': true,
          'search.minStalenessInterval': '5m',
          'promscrape.configCheckInterval': '5m',
          retentionPeriod: '8w',
          'search.maxPointsSubqueryPerTimeseries': '500000',
        },
        persistentVolume: {
          enabled: true,
          existingClaim: 'victoria-metrics',
        },
        ingress: { enabled: false },
        resources: {
          requests: { memory: '1536Mi' },
          limits: { memory: '1536Mi' },
        },
        scrape: {
          enabled: true,
          [if $.victoria_metrics.extra_scrape_rendered != null then 'extraScrapeConfigs']: $.victoria_metrics.extra_scrape_rendered,
          config: {
            scrape_configs: [
              {
                job_name: 'victoriametrics',
                dns_sd_configs: [
                  {
                    names: [
                      'victoria-metrics-alert-server.monitoring.svc.cluster.local',
                      'victoria-metrics-single-server.monitoring.svc.cluster.local',
                    ],
                    type: 'SRV',
                  },
                ],
              },
              {
                job_name: 'kubernetes-apiservers',
                kubernetes_sd_configs: [
                  { role: 'endpoints' },
                ],
                scheme: 'https',
                tls_config: {
                  ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
                  insecure_skip_verify: true,
                },
                bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',
                relabel_configs: [
                  {
                    source_labels: ['__meta_kubernetes_namespace', '__meta_kubernetes_service_name', '__meta_kubernetes_endpoint_port_name'],
                    action: 'keep',
                    regex: 'default;kubernetes;https',
                  },
                ],
              },
              {
                job_name: 'kubernetes-nodes',
                scheme: 'https',
                tls_config: {
                  ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
                  insecure_skip_verify: true,
                },
                bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',
                kubernetes_sd_configs: [
                  { role: 'node' },
                ],
                relabel_configs: [
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_node_label_(.+)',
                  },
                  {
                    target_label: '__address__',
                    replacement: 'kubernetes.default.svc:443',
                  },
                  {
                    source_labels: ['__meta_kubernetes_node_name'],
                    regex: '(.+)',
                    target_label: '__metrics_path__',
                    replacement: '/api/v1/nodes/$1/proxy/metrics',
                  },
                ],
              },
              {
                job_name: 'kubernetes-nodes-cadvisor',
                scheme: 'https',
                tls_config: {
                  ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
                  insecure_skip_verify: true,
                },
                bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',
                kubernetes_sd_configs: [
                  { role: 'node' },
                ],
                relabel_configs: [
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_node_label_(.+)',
                  },
                  {
                    target_label: '__address__',
                    replacement: 'kubernetes.default.svc:443',
                  },
                  {
                    source_labels: ['__meta_kubernetes_node_name'],
                    regex: '(.+)',
                    target_label: '__metrics_path__',
                    replacement: '/api/v1/nodes/$1/proxy/metrics/cadvisor',
                  },
                ],
              },
              {
                job_name: 'kubernetes-service-endpoints',
                honor_labels: true,
                scrape_interval: '10s',
                scrape_timeout: '5s',
                kubernetes_sd_configs: [
                  { role: 'endpoints' },
                ],
                relabel_configs: [
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_scrape'],
                    action: 'keep',
                    regex: true,
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_scrape_slow'],
                    action: 'drop',
                    regex: true,
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_scheme'],
                    action: 'replace',
                    target_label: '__scheme__',
                    regex: '(https?)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_path'],
                    action: 'replace',
                    target_label: '__metrics_path__',
                    regex: '(.+)',
                  },
                  {
                    source_labels: ['__address__', '__meta_kubernetes_service_annotation_prometheus_io_port'],
                    action: 'replace',
                    target_label: '__address__',
                    regex: '(.+?)(?::\\d+)?;(\\d+)',
                    replacement: '${1}:${2}',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_service_annotation_prometheus_io_param_(.+)',
                    replacement: '__param_${1}',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_service_label_(.+)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_namespace'],
                    action: 'replace',
                    target_label: 'namespace',
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_name'],
                    action: 'replace',
                    target_label: 'service',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_node_name'],
                    action: 'replace',
                    target_label: 'node',
                  },
                ],
              },
              {
                job_name: 'kubernetes-service-endpoints-slow',
                honor_labels: true,
                scrape_interval: '5m',
                scrape_timeout: '30s',
                kubernetes_sd_configs: [
                  { role: 'endpoints' },
                ],
                relabel_configs: [
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_scrape_slow'],
                    action: 'keep',
                    regex: true,
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_scheme'],
                    action: 'replace',
                    target_label: '__scheme__',
                    regex: '(https?)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_path'],
                    action: 'replace',
                    target_label: '__metrics_path__',
                    regex: '(.+)',
                  },
                  {
                    source_labels: ['__address__', '__meta_kubernetes_service_annotation_prometheus_io_port'],
                    action: 'replace',
                    target_label: '__address__',
                    regex: '(.+?)(?::\\d+)?;(\\d+)',
                    replacement: '${1}:${2}',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_service_annotation_prometheus_io_param_(.+)',
                    replacement: '__param_${1}',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_service_label_(.+)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_namespace'],
                    action: 'replace',
                    target_label: 'namespace',
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_name'],
                    action: 'replace',
                    target_label: 'service',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_node_name'],
                    action: 'replace',
                    target_label: 'node',
                  },
                ],
              },
              {
                job_name: 'kubernetes-services',
                honor_labels: true,
                metrics_path: '/probe',
                params: {
                  module: ['http_2xx'],
                },
                kubernetes_sd_configs: [
                  { role: 'service' },
                ],
                relabel_configs: [
                  {
                    source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_probe'],
                    action: 'keep',
                    regex: true,
                  },
                  {
                    source_labels: ['__address__'],
                    target_label: '__param_target',
                  },
                  {
                    target_label: '__address__',
                    replacement: 'blackbox',
                  },
                  {
                    source_labels: ['__param_target'],
                    target_label: 'instance',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_service_label_(.+)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_namespace'],
                    target_label: 'namespace',
                  },
                  {
                    source_labels: ['__meta_kubernetes_service_name'],
                    target_label: 'service',
                  },
                ],
              },
              {
                job_name: 'kubernetes-pods',
                honor_labels: true,
                kubernetes_sd_configs: [
                  { role: 'pod' },
                ],
                relabel_configs: [
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scrape'],
                    action: 'keep',
                    regex: true,
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scrape_slow'],
                    action: 'drop',
                    regex: true,
                  },
                  {
                    action: 'drop',
                    source_labels: ['__meta_kubernetes_pod_container_init'],
                    regex: true,
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scheme'],
                    action: 'replace',
                    regex: '(https?)',
                    target_label: '__scheme__',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_path'],
                    action: 'replace',
                    target_label: '__metrics_path__',
                    regex: '(.+)',
                  },
                  {
                    source_labels: ['__address__', '__meta_kubernetes_pod_annotation_prometheus_io_port'],
                    action: 'replace',
                    regex: '(.+?)(?::\\d+)?;(\\d+)',
                    replacement: '${1}:${2}',
                    target_label: '__address__',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_pod_annotation_prometheus_io_param_(.+)',
                    replacement: '__param_${1}',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_pod_label_(.+)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_namespace'],
                    action: 'replace',
                    target_label: 'namespace',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_name'],
                    action: 'replace',
                    target_label: 'pod',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_phase'],
                    regex: 'Pending|Succeeded|Failed|Completed',
                    action: 'drop',
                  },
                ],
              },
              {
                job_name: 'kubernetes-pods-slow',
                honor_labels: true,
                scrape_interval: '5m',
                scrape_timeout: '30s',
                kubernetes_sd_configs: [
                  { role: 'pod' },
                ],
                relabel_configs: [
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scrape_slow'],
                    action: 'keep',
                    regex: true,
                  },
                  {
                    action: 'drop',
                    source_labels: ['__meta_kubernetes_pod_container_init'],
                    regex: true,
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scheme'],
                    action: 'replace',
                    regex: '(https?)',
                    target_label: '__scheme__',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_path'],
                    action: 'replace',
                    target_label: '__metrics_path__',
                    regex: '(.+)',
                  },
                  {
                    source_labels: ['__address__', '__meta_kubernetes_pod_annotation_prometheus_io_port'],
                    action: 'replace',
                    regex: '(.+?)(?::\\d+)?;(\\d+)',
                    replacement: '${1}:${2}',
                    target_label: '__address__',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_pod_annotation_prometheus_io_param_(.+)',
                    replacement: '__param_${1}',
                  },
                  {
                    action: 'labelmap',
                    regex: '__meta_kubernetes_pod_label_(.+)',
                  },
                  {
                    source_labels: ['__meta_kubernetes_namespace'],
                    action: 'replace',
                    target_label: 'namespace',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_name'],
                    action: 'replace',
                    target_label: 'pod',
                  },
                  {
                    source_labels: ['__meta_kubernetes_pod_phase'],
                    regex: 'Pending|Succeeded|Failed|Completed',
                    action: 'drop',
                  },
                ],
              },
            ],
          },
        },
      },
    }),
    helm_blackbox_exporter: $._custom.helm.new('prometheus-blackbox-exporter', 'https://prometheus-community.github.io/helm-charts', $._version.blackbox_exporter.chart, 'monitoring', {
      securityContext: {
        capabilities: {
          drop: ['ALL'],
          add: ['NET_RAW'],
        },
      },
      config: {
        modules: {
          icmp: {
            prober: 'icmp',
            timeout: '2s',
            icmp: {
              preferred_ip_protocol: 'ip4',
            },
          },
        },
      },
    }),
    helm_prometheus: $._custom.helm.new('prometheus', 'https://prometheus-community.github.io/helm-charts', $._version.prometheus.chart, 'monitoring', {
      extraEnv: { TZ: $._config.tz },
      alertmanager: {
        resources: {
          requests: { memory: '32Mi' },
          limits: { memory: '64Mi' },
        },
        baseURL: std.format('https://alertmanager.%s', std.extVar('secrets').domain),
        enabled: true,
        persistence: {
          enabled: true,
          storageClass: std.get($.storage.class_without_snapshot.metadata, 'name'),
          size: '128Mi',
        },
        configmapReload: {
          enabled: true,
          resources: {
            requests: { memory: '16Mi' },
            limits: { memory: '32Mi' },
          },
        },
        config: {
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
      'prometheus-pushgateway': { enabled: false },
      'kube-state-metrics': {
        enabled: true,
        resources: {
          requests: { memory: '32Mi' },
          limits: { memory: '64Mi' },
        },
      },
      'prometheus-node-exporter': {
        enabled: true,
        resources: {
          requests: { memory: '32Mi' },
          limits: { memory: '64Mi' },
        },
      },
      server: {
        replicaCount: 0,
        persistentVolume: { enabled: false },
      },
    }),
  },
}
