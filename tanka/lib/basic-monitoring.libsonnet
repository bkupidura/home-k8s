{
  logging: {
    parsers:: {
    },
    rules:: [
      {
        name: 'k8s',
        interval: '5m',
        rules: [
          {
            record: 'k8s:error_logs:5m',
            expr: '_time:5m i("error") | stats by (kubernetes__pod_name, kubernetes__namespace_name, kubernetes__labels__app__kubernetes__io__name) count() as log_count',
          },
          {
            record: 'k8s:warning_logs:5m',
            expr: '_time:5m i("warning") | stats by (kubernetes__pod_name, kubernetes__namespace_name, kubernetes__labels__app__kubernetes__io__name) count() as log_count',
          },
          {
            record: 'k8s:all_logs:5m',
            expr: '_time:5m | stats by (kubernetes__pod_name, kubernetes__namespace_name, kubernetes__labels__app__kubernetes__io__name) count() as log_count',
          },
        ],
      },
      {
        name: 'backup',
        interval: '1m',
        rules: [
          {
            alert: 'BackupError',
            expr: '_time:5m kubernetes__container_name: "backup" and i("error") | stats by (kubernetes__pod_name) count() as log_count | filter log_count :> 0',
            labels: { service: 'backup', severity: 'warning' },
            annotations: {
              summary: 'Errors observed on backup job {{ index $labels "kubernetes__pod_name" }}',
            },
          },
        ],
      },
    ],
  },
  monitoring: {
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
            expr: 'delta(node_vmstat_oom_kill[30m]) > 1',
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
            expr: 'node_load1 > on (node) (count by (node) (node_cpu_seconds_total{mode="system"})) * 2',
            'for': '15m',
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
            expr: 'min by (device, instance) (node_filesystem_free_bytes{device=~"/dev/[a-z]d[a-z][0-9]*"} / node_filesystem_size_bytes) < 0.1',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High disk usage on {{ $labels.node }} on {{ $labels.device }} mounted as {{ $labels.mountpoint }}',
            },
          },
          {
            alert: 'PhysicalCPUThrotling',
            expr: 'delta(node_cpu_core_throttles_total[15m]) > 0',
            'for': '60m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'Physical CPU throtling on {{ $labels.node }}',
            },
          },
          {
            alert: 'HighTemperatureConstant',
            expr: 'node_hwmon_temp_celsius / node_hwmon_temp_crit_celsius > 0.95',
            'for': '15m',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High temperature observed on {{ $labels.node }} for {{ $labels.chip }}/{{ $labels.sensor }}',
            },
          },
          {
            alert: 'HighTemperatureMultipleTimes',
            expr: 'sum by (node, chip, sensor) (sum_over_time((node_hwmon_temp_celsius / node_hwmon_temp_crit_celsius > 0.95)[1h])) > 5',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High temperature observed multiple times in last 1h on {{ $labels.node }} for {{ $labels.chip }}/{{ $labels.sensor }}',
            },
          },
        ],
      },
      {
        name: 'infra-slow30m',
        interval: '30m',
        rules: [
          {
            alert: 'HighContextSwitch',
            expr: 'rate(node_context_switches_total[10m]) > rate(node_context_switches_total[60m] offset 60m) * 1.3',
            'for': '2h',
            labels: { service: 'system', severity: 'warning' },
            annotations: {
              summary: 'High number of context switching observed on {{ $labels.node }}',
            },
          },
        ],
      },
      {
        name: 'k8s-slow1h',
        interval: '1h',
        rules: [
        ],
      },
      {
        name: 'k8s-slow5m',
        interval: '5m',
        rules: [
          {
            alert: 'K8sHighCPUHVLimit',
            expr: 'sum by (kubernetes_io_hostname) (container_spec_cpu_quota{container!=""} / 100) / on (kubernetes_io_hostname) label_replace(kube_node_status_allocatable{resource="cpu"} * 1000, "kubernetes_io_hostname", "$1", "node", "(.+)") > 1.3',
            'for': '30m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'PODs running on {{ $labels.kubernetes_io_hostname }} have higher CPU limits than total HV capacity',
            },
          },
          {
            alert: 'K8sHighMemoryHVUsage',
            expr: 'sum by (kubernetes_io_hostname) (container_memory_working_set_bytes{container!=""}) / on (kubernetes_io_hostname) label_replace(kube_node_status_allocatable{resource="memory"}, "kubernetes_io_hostname", "$1", "node", "(.+)") > 0.9',
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
            expr: 'max by (pod, namespace) (container_memory_working_set_bytes{container!~"(unifi|)"} / container_spec_memory_limit_bytes < Inf) > 0.95',
            'for': '30m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'POD {{ $labels.pod }} is using {{ $value | humanizePercentage }} of memory limit',
            },
          },
        ],
      },
      {
        name: 'k8s',
        rules: [
          {
            alert: 'K8sPodErrorsIncreasing',
            expr: 'k8s:error_logs:5m / avg_over_time(k8s:error_logs:5m[2h] offset 30m) > 1.5 and avg_over_time(k8s:error_logs:5m[2h] offset 30m) > 5',
            'for': '5m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Observing error logs increase for POD {{ index $labels "kubernetes__namespace_name" }}/{{ index $labels "kubernetes__pod_name" }}',
            },
          },
          {
            alert: 'K8sPodErrorsHigh',
            expr: 'avg_over_time(k8s:error_logs:5m[10m]) > 300',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Observing high number of error logs for POD {{ index $labels "kubernetes__namespace_name" }}/{{ index $labels "kubernetes__pod_name" }}',
            },
          },
          {
            alert: 'K8sPodLogsIncreasing',
            expr: 'k8s:all_logs:5m / avg_over_time(k8s:all_logs:5m[2h] offset 60m) > 2 and avg_over_time(k8s:all_logs:5m[2h] offset 60m) > 30',
            'for': '30m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'Observing logs increase for POD {{ index $labels "kubernetes__namespace_name" }}/{{ index $labels "kubernetes__pod_name" }}',
            },
          },
          {
            alert: 'K8sVolumeUsageHigh',
            expr: 'kubelet_volume_stats_used_bytes{job="kubernetes-nodes"} / (kubelet_volume_stats_capacity_bytes < 10*1024*1024*1024) > 0.90',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Volume for PVC {{ $labels.persistentvolumeclaim }} is using more than 90% of available storage',
            },
          },
          {
            alert: 'K8sVolumeUsageHigh',
            expr: 'kubelet_volume_stats_used_bytes{job="kubernetes-nodes"} / (10*1024*1024*1024 <= kubelet_volume_stats_capacity_bytes < 100*1024*1024*1024) > 0.95',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Volume for PVC {{ $labels.persistentvolumeclaim }} is using more than 95% of available storage',
            },
          },
          {
            alert: 'K8sVolumeUsageHigh',
            expr: 'kubelet_volume_stats_used_bytes{job="kubernetes-nodes"} / (100*1024*1024*1024 <= kubelet_volume_stats_capacity_bytes) > 0.99',
            'for': '10m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Volume for PVC {{ $labels.persistentvolumeclaim }} is using more than 99% of available storage',
            },
          },
          {
            alert: 'K8sVolumeUsageLow',
            expr: 'avg_over_time(kubelet_volume_stats_used_bytes{job="kubernetes-nodes", persistentvolumeclaim!="valkey"}[15m]) * 2 < avg_over_time(kubelet_volume_stats_used_bytes{job="kubernetes-nodes"}[2h] offset 1h)',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Volume for PVC {{ $labels.persistentvolumeclaim }} is using less than 50% of storage used in last 2h. Possible data loss.',
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
            alert: 'K8sDeploymentCountDifference',
            expr: 'abs(delta(count(kube_deployment_status_replicas)[1h])) > 0',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Deployment count difference detected',
            },
          },
          {
            alert: 'K8sSTSCountDifference',
            expr: 'abs(delta(count(kube_statefulset_status_replicas)[1h])) > 0',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Statefulset count difference detected',
            },
          },
          {
            alert: 'K8sDaemonSetCountDifference',
            expr: 'abs(delta(count(kube_daemonset_status_number_available)[1h])) > 0',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'DaemonSet count difference detected',
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
            expr: 'delta(kube_pod_container_status_restarts_total[2h]) > 2',
            'for': '1m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'Pod {{ $labels.pod }} was restarted {{ humanize $value }} times in last 2h',
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
            alert: 'K8sPodsUnexpectedPhase',
            expr: 'sum by (phase) (kube_pod_status_phase{phase=~"(Failed|Pending|Unknown)"}) > 0',
            'for': '10m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: 'Pod in {{ $labels.phase }} state observerd',
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
          {
            record: 'k8s:container:cpu:throthling:5m',
            expr: 'sum(increase(container_cpu_cfs_throttled_periods_total{container!=""}[5m])) by (container, pod, namespace) / sum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace)',
          },
          {
            alert: 'K8sPodCPUThrotling',
            expr: 'k8s:container:cpu:throthling:5m > 0.7',
            'for': '30m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: '{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}',
            },
          },
          {
            alert: 'K8sPodCPUThrotling',
            expr: 'k8s:container:cpu:throthling:5m > 0.5',
            'for': '60m',
            labels: { service: 'k8s', severity: 'info' },
            annotations: {
              summary: '{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}',
            },
          },
        ],
      },
    ],
  },
}
