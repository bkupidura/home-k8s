{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  prometheus: {
    rules:: [
      {
        name: 'infra',
        rules: [
          {
            alert: 'SystemNodeRebooted',
            expr: 'time() - node_boot_time_seconds < 600',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: '{{ $labels.node }} was rebooted',
            },
          },
          {
            alert: 'SystemOOMKill',
            expr: 'delta(node_vmstat_oom_kill[30m]) > 0',
            'for': '1m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'Out of memory kill observed on {{ $labels.node }}',
            },
          },
          {
            alert: 'SystemHighMaxErrorTimeDrift',
            expr: 'node_timex_maxerror_seconds > 0.5',
            'for': '5m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High max error time drift observed on {{ $labels.node }}',
            },
          },
          {
            alert: 'System1MLoadHigh',
            expr: 'node_load1 > on (node) (count by (node) (node_cpu_seconds_total{mode="system"})) * 1.5',
            'for': '10m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High load avg {{ humanize $value }} from 1m on {{ $labels.node }}',
            },
          },
          {
            alert: 'System15MLoadHigh',
            expr: 'node_load15 > on (node) (count by (node) (node_cpu_seconds_total{mode="system"})) * 0.95',
            'for': '60m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High load avg {{ humanize $value }} from 15m on {{ $labels.node }}',
            },
          },
          {
            alert: 'SystemHighMemory',
            expr: 'node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1',
            'for': '10m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'Low free memory {{ $value | humanizePercentage }} on {{ $labels.node }}',
            },
          },
          {
            alert: 'SystemLowDisk',
            expr: 'min by (device, instance) (node_filesystem_free_bytes{device=~"/dev/[a-z]d[a-z][0-9]*"} / node_filesystem_size_bytes) < 0.3',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High disk usage on {{ $labels.node }} on {{ $labels.device }} mounted as {{ $labels.mountpoint }}',
            },
          },
        ],
      },
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
      {
        name: 'k8s',
        rules: [
          {
            alert: 'K8sVolumeUsageHigh',
            expr: 'kubelet_volume_stats_used_bytes{job="kubernetes-nodes"} / kubelet_volume_stats_capacity_bytes > 0.75',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Volume for PVC {{ $labels.persistentvolumeclaim }} is using more than 75% os available storage',
            },
          },
          {
            alert: 'K8sStatefulSetUnhealthy',
            expr: 'kube_statefulset_status_replicas_ready / kube_statefulset_status_replicas < 0.7',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'StatefulSet {{ $labels.statefulset }} have less than 70% of available replicas ready',
            },
          },
          {
            alert: 'K8sDeploymentUnhealthy',
            expr: 'kube_deployment_status_replicas_available / kube_deployment_status_replicas < 0.7',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Deployment {{ $labels.deployment }} have less than 70% of available replicas ready',
            },
          },
          {
            alert: 'K8sHighCPUHVLimit',
            expr: 'sum by (kubernetes_io_hostname) (container_spec_cpu_quota{container!=""} / 100) / on (kubernetes_io_hostname) label_replace(kube_node_status_allocatable{resource="cpu"} * 1000, "kubernetes_io_hostname", "$1", "node", "(.+)") > 1',
            'for': '30m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'PODs running on {{ $labels.kubernetes_io_hostname }} have higher CPU limits than total HV capacity',
            },
          },
          {
            alert: 'K8sHighMemoryHVUsage',
            expr: 'sum by (kubernetes_io_hostname) (container_memory_working_set_bytes{container!=""}) / on (kubernetes_io_hostname) label_replace(kube_node_status_allocatable{resource="memory"}, "kubernetes_io_hostname", "$1", "node", "(.+)") > 0.8',
            'for': '30m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'PODs running on {{ $labels.kubernetes_io_hostname }} are using 80% of HV total memory',
            },
          },
          {
            alert: 'K8sHighMemoryHVLimit',
            expr: 'sum by (kubernetes_io_hostname) (container_spec_memory_limit_bytes{container!=""}) / on (kubernetes_io_hostname) label_replace(kube_node_status_allocatable{resource="memory"}, "kubernetes_io_hostname", "$1", "node", "(.+)") > 1',
            'for': '30m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'PODs running on {{ $labels.kubernetes_io_hostname }} have higher memory limits than 90% of HV total memory',
            },
          },
          {
            alert: 'K8sHighMemoryPodUsage',
            expr: 'max by (pod, namespace) (container_memory_working_set_bytes{container!=""} / container_spec_memory_limit_bytes < Inf) > 0.95',
            'for': '30m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'POD {{ $labels.pod }} is using {{ $value | humanizePercentage }} of memory limit',
            },
          },
          {
            alert: 'K8sClusterRunningDifferentK8sVersionComponets',
            expr: 'count (count by (git_version) (kubernetes_build_info)) > 1',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Some components running in cluster have different k8s git_version than others',
            },
          },
          {
            alert: 'K8sNodeNotReady',
            expr: 'kube_node_status_condition{condition="Ready",status="true"} != 1',
            'for': '5m',
            labels: { service: 'k8s', severity: 'critical' },
            annotations: {
              summary: '{{ $labels.node }} is unready',
            },
          },
          {
            alert: 'K8sNodeReadinesFlapping',
            expr: 'sum by (node) (changes(kube_node_status_condition{status="true",condition="Ready"}[10m])) > 2',
            'for': '5m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: '{{ $labels.node }} is readiness is flapping',
            },
          },
          {
            alert: 'K8sPodCPUThrotling',
            expr: 'sum(increase(container_cpu_cfs_throttled_periods_total{container!~"^(frigate|)$"}[5m])) by (container, pod, namespace) / sum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace) > 0.5',
            'for': '15m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: '{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}',
            },
          },
          {
            alert: 'K8sPodCPUThrotling',
            expr: 'sum(increase(container_cpu_cfs_throttled_periods_total{container!~"^(frigate|)$"}[5m])) by (container, pod, namespace) / sum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace) > 0.3',
            'for': '30m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: '{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}',
            },
          },
          {
            alert: 'K8sNodeUnschedulable',
            expr: 'kube_node_spec_unschedulable != 0',
            'for': '2m',
            labels: { service: 'k8s', severity: 'critical' },
            annotations: {
              summary: 'K8s node {{ $labels.node }} is unschedulable',
            },
          },
          {
            alert: 'K8sJobIsNotCompleted',
            expr: 'kube_job_spec_completions - kube_job_status_succeeded > 0',
            'for': '3h',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'Job {{ $labels.job_name }} is not done for last 3h',
            },
          },
          {
            alert: 'K8sJobFailed',
            expr: 'kube_job_status_failed > 0',
            'for': '5m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Job {{ $labels.job_name }} is in failed state',
            },
          },
          {
            alert: 'K8sPodsRestarts',
            expr: 'delta(kube_pod_container_status_restarts_total[30m]) > 2',
            'for': '1m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Pod {{ $labels.pod }} was restarted {{ humanize $value }} times in last 30m',
            },
          },
          {
            alert: 'K8sPodsWaiting',
            expr: 'max by (pod) (kube_pod_container_status_waiting) > 0',
            'for': '10m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'Pod {{ $labels.pod }} is in waiting state for last 10m',
            },
          },
          {
            alert: 'K8sDaemonSetUnavailable',
            expr: 'kube_daemonset_status_number_unavailable != 0',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Daemonset {{ $labels.daemonset }} has unavailable copies for last 10m',
            },
          },
          {
            alert: 'K8sWrongNumberOfDaemonSet',
            expr: '(kube_daemonset_status_current_number_scheduled / kube_daemonset_status_desired_number_scheduled != 1) or (kube_daemonset_status_number_ready / kube_daemonset_status_desired_number_scheduled != 1)',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Daemonset {{ $labels.daemonset }} has wrong number of copies',
            },
          },
          {
            alert: 'K8sEndpointNotReady',
            expr: 'kube_endpoint_address_not_ready / (kube_endpoint_address_not_ready + kube_endpoint_address_available) > 0.4',
            'for': '5m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'Endpoint {{ $labels.endpoint }} has more than 40% of not ready members for last 5m',
            },
          },
          {
            alert: 'K8sPendingPods',
            expr: 'scheduler_pending_pods{job="kubernetes-nodes"} > 0',
            'for': '5m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Pending pods on {{ $labels.kubernetes_io_hostname }} in queue {{ $labels.queue }}',
            },
          },
          {
            alert: 'K8sRunningPodsFlapping',
            expr: 'abs(delta(kubelet_running_pods{job="kubernetes-nodes"}[1h])) > 2',
            'for': '20m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Flapping pods on {{ $labels.kubernetes_io_hostname }}',
            },
          },
        ],
      },
    ],
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        rules: group.rules,
      }
      for group in $.prometheus.rules
    ],
    extra_scrape:: {},
    extra_scrape_rendered:: [
      $.prometheus.extra_scrape[extra_scrape]
      for extra_scrape in std.objectFields($.prometheus.extra_scrape)
    ],
    pvc_prometheus: p.new('prometheus-server')
                    + p.metadata.withNamespace('home-infra')
                    + p.spec.withAccessModes(['ReadWriteOnce'])
                    + p.spec.withStorageClassName('longhorn-standard')
                    + p.spec.resources.withRequests({ storage: '10Gi' }),
    pvc_alertmanager: p.new('alertmanager')
                      + p.metadata.withNamespace('home-infra')
                      + p.spec.withAccessModes(['ReadWriteOnce'])
                      + p.spec.withStorageClassName('longhorn-standard')
                      + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route_prometheus: $._custom.ingress_route.new('prometheus', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`prometheus.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'prometheus-server', port: 80, namespace: 'home-infra' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    ingress_route_alertmanager: $._custom.ingress_route.new('alertmanager', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`alertmanager.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'prometheus-alertmanager', port: 80, namespace: 'home-infra' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    helm: $._custom.helm.new('prometheus', 'https://prometheus-community.github.io/helm-charts', $._version.prometheus.chart, 'home-infra', {
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
          requests: { memory: '2Gi' },
          limits: { memory: '2Gi' },
        },
        global: { external_labels: { cluster: 'k3s' } },
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
