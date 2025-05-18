{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    extra_scrape+:: {
      [std.format('blackbox_icmp_%s', group_name)]: {
        job_name: std.format('blackbox-icmp-%s', group_name),
        relabel_configs: [
          { source_labels: ['__address__'], target_label: '__param_target' },
          { source_labels: ['__param_target'], target_label: 'instance' },
          { target_label: '__address__', replacement: 'prometheus-blackbox-exporter.monitoring:9115' },
        ],
        metrics_path: '/probe',
        params: {
          module: ['icmp'],
        },
        scrape_interval: '10s',
        static_configs: std.extVar('secrets').monitoring.blackbox_ping[group_name],
      }
      for group_name in std.objectFields(std.extVar('secrets').monitoring.blackbox_ping)
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
            'for': '10m',
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
          {
            alert: 'Watchdog',
            expr: 'scalar(1)',
            labels: { service: 'dmh-watchdog', severity: 'info' },
          },
          {
            alert: 'DMHVMActionDefined',
            expr: 'dmh_actions{name="dmh-victoria-metrics", processed="0"} <= 0',
            labels: { service: 'dmh', severity: 'critical' },
            annotations: {
              summary: 'There is no defined actions for dead-man-hand for Victoria Metrics',
            },
          },
        ],
      },
    ],
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('vm-alert.%s', std.extVar('secrets').domain),
            std.format('vm-server.%s', std.extVar('secrets').domain),
            std.format('alertmanager.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:admin',
          policy: 'one_factor',
        },
      },
    ],
  },
  victoria_metrics: {
    restore:: $._config.restore,
    [if $.monitoring.extra_scrape != null then 'extra_scrape_rendered']:: [
      $.monitoring.extra_scrape[extra_scrape]
      for extra_scrape in std.objectFields($.monitoring.extra_scrape)
    ],
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        [if std.get(group, 'interval') != null then 'interval']: group.interval,
        rules: group.rules,
      }
      for group in $.monitoring.rules
    ],
    pvc_server: p.new('victoria-metrics')
                + p.metadata.withNamespace('monitoring')
                + p.spec.withAccessModes(['ReadWriteOnce'])
                + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
                + p.spec.resources.withRequests({ storage: '20Gi' }),
    ingress_route_alert: $._custom.ingress_route.new('victoria-metrics-alert', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`vm-alert.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'victoria-metrics-alert-server', port: 8880, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    ingress_route_server: $._custom.ingress_route.new('victoria-metrics', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`vm-server.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'victoria-metrics-single-server', port: 8428, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    ingress_route_alertmanager: $._custom.ingress_route.new('alertmanager', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`alertmanager.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'alertmanager', port: 9093, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    helm_alert: $._custom.helm.new('victoria-metrics-alert', 'victoria-metrics-alert', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.alert.chart, 'monitoring', {
      server: {
        enabled: true,
        resources: {
          requests: { memory: '25Mi' },
          limits: { memory: '50Mi' },
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
            url: 'http://alertmanager.monitoring:9093',
          },
        },
        config: {
          alerts: {
            groups: std.prune($.victoria_metrics.rules_rendered),
          },
        },
        podAnnotations: {
          'fluentbit.io/parser': 'json',
        },
      },
    }),
    helm_server: $._custom.helm.new('victoria-metrics-single', 'victoria-metrics-single', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.server.chart, 'monitoring', {
      server: {
        enabled: true,
        extraArgs: {
          'promscrape.suppressDuplicateScrapeTargetErrors': true,
          'search.minStalenessInterval': '5m',
          'promscrape.configCheckInterval': '5m',
          retentionPeriod: '4w',
          'search.maxPointsSubqueryPerTimeseries': '500000',
        },
        persistentVolume: {
          enabled: true,
          existingClaim: 'victoria-metrics',
        },
        ingress: { enabled: false },
        resources: {
          requests: { memory: '600M' },
          limits: { memory: '1200M' },
        },
        podAnnotations: {
          'fluentbit.io/parser': 'json',
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
                    regex: '__param_(.+)',
                    replacement: 'param_${1}',
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
    helm_blackbox_exporter: $._custom.helm.new('prometheus-blackbox-exporter', 'prometheus-blackbox-exporter', 'https://prometheus-community.github.io/helm-charts', $._version.blackbox_exporter.chart, 'monitoring', {
      securityContext: {
        capabilities: {
          drop: ['ALL'],
          add: ['NET_RAW'],
        },
      },
      podAnnotations: {
        'fluentbit.io/parser': 'logfmt',
      },
      resources: {
        requests: { memory: '16Mi', cpu: '20m' },
        limits: { memory: '32Mi', cpu: '50m' },
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
    helm_alertmanager: $._custom.helm.new('alertmanager', 'alertmanager', 'https://prometheus-community.github.io/helm-charts', $._version.alertmanager.chart, 'monitoring', {
      resources: {
        requests: { memory: '32Mi' },
        limits: { memory: '64Mi' },
      },
      baseURL: std.format('https://alertmanager.%s', std.extVar('secrets').domain),
      enabled: true,
      persistence: {
        enabled: true,
        storageClass: std.get($.storage.class_with_encryption.metadata, 'name'),
        size: '128Mi',
      },
      configmapReload: {
        enabled: true,
        resources: {
          requests: { memory: '16Mi' },
          limits: { memory: '32Mi' },
        },
      },
      podAnnotations: {
        'fluentbit.io/parser': 'logfmt',
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
          {
            name: 'dmh',
            webhook_configs: [
              {
                send_resolved: false,
                url: 'http://dmh-victoria-metrics.monitoring:8080/api/alive',
                timeout: '3s',
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
          routes: [
            {
              receiver: 'dmh',
              matchers: [
                'service="dmh-watchdog"',
              ],
              group_wait: '10s',
              group_interval: '1m',
              repeat_interval: '5m',
            },
          ],
        },
        inhibit_rules: [
          { equal: ['service'], source_matchers: ['severity = critical', 'service !~ system|k8s'], target_matchers: ['severity = warning'] },
          { equal: ['service'], source_matchers: ['severity = warning', 'service !~ system|k8s'], target_matchers: ['severity = info'] },
        ],
      },
    }),
    helm_kube_state_metrics: $._custom.helm.new('kube-state-metrics', 'kube-state-metrics', 'https://prometheus-community.github.io/helm-charts', $._version.kube_state_metrics.chart, 'monitoring', {
      resources: {
        requests: { memory: '32Mi' },
        limits: { memory: '64Mi' },
      },
    }),
    helm_node_exporter: $._custom.helm.new('prometheus-node-exporter', 'prometheus-node-exporter', 'https://prometheus-community.github.io/helm-charts', $._version.node_exporter.chart, 'monitoring', {
      resources: {
        requests: { memory: '32Mi' },
        limits: { memory: '64Mi' },
      },
      podAnnotations: {
        'fluentbit.io/parser': 'logfmt',
      },
    }),
    pvc_dmh: p.new('dmh-victoria-metrics')
             + p.metadata.withNamespace('monitoring')
             + p.spec.withAccessModes(['ReadWriteOnce'])
             + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
             + p.spec.resources.withRequests({ storage: '50Mi' }),
    cronjob_backup: $._custom.cronjob_backup.new('dmh-victoria-metrics', 'monitoring', '10 05 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'dmh-victoria-metrics'),
    cronjob_restore: $._custom.cronjob_restore.new('dmh-victoria-metrics', 'monitoring', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'dmh-victoria-metrics'),
    service: s.new('dmh-victoria-metrics', { 'app.kubernetes.io/name': 'dmh-victoria-metrics' }, [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('monitoring')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'dmh-victoria-metrics' }),
    config: v1.configMap.new('dmh-victoria-metrics-config', {
              'config.yaml': std.manifestYamlDoc({
                components: ['dmh', 'vault'],
                state: { file: '/data/state.json' },
                vault: { file: '/data/vault.json', key: std.extVar('secrets').dmh.vault.key },
                action: { process_unit: 'minute' },
                remote_vault: {
                  client_uuid: 'dmh-victoria-metrics',
                  url: 'http://127.0.0.1:8080',
                },
                execute: {
                  plugin: {
                    bulksms: { routing_group: 'premium', token: { id: std.extVar('secrets').dmh.execute.plugin.bulksms.token.id, secret: std.extVar('secrets').dmh.execute.plugin.bulksms.token.secret } },
                    mail: {
                      username: std.extVar('secrets').smtp.username,
                      password: std.extVar('secrets').smtp.password,
                      server: std.extVar('secrets').smtp.server,
                      from: std.format('dmh-victoria-metrics@%s', std.extVar('secrets').domain),
                      tls_policy: 'tls_mandatory',
                    },
                  },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('monitoring'),
    deployment: d.new('dmh-victoria-metrics',
                      if $.victoria_metrics.restore then 0 else 1,
                      [
                        c.new('dmh', $._version.dmh.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8080, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          DMH_CONFIG_FILE: '/config/config.yaml',
                        })
                        + c.resources.withRequests({ memory: '16Mi', cpu: '20m' })
                        + c.resources.withLimits({ memory: '32Mi', cpu: '40m' })
                        + c.readinessProbe.httpGet.withPath('/ready')
                        + c.readinessProbe.httpGet.withPort(8080)
                        + c.readinessProbe.withInitialDelaySeconds(5)
                        + c.readinessProbe.withPeriodSeconds(5)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort(8080)
                        + c.livenessProbe.withInitialDelaySeconds(5)
                        + c.livenessProbe.withPeriodSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'dmh-victoria-metrics' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.configVolumeMount('dmh-victoria-metrics-config', '/config/', {})
                + d.pvcVolumeMount('dmh-victoria-metrics', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('monitoring')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                }),
  },
}
