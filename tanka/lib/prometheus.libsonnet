{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  prometheus: {
    rules:: [
      {
        name: 'restic',
        rules: [
          {
            alert: 'ResticNoNewBackup',
            expr: 'delta(rest_server_blob_write_bytes_total{type="snapshots"}[5d]) <= 0',
            'for': '1d',
            labels: { service: 'restic', severity: 'warning' },
            annotations: {
              summary: 'No new backups found for repo {{ $labels.repo }}',
            },
          },
        ],
      },
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
            alert: 'TraefikServiceErrors4XX',
            expr: 'sum by (service, protocol) (delta(traefik_service_requests_total{code=~"4.."}[5m])) / sum by(service, protocol) (delta(traefik_service_requests_total{code!~"(4|5).."}[5m])) > 0.3',
            'for': '10m',
            labels: { service: 'traefik', severity: 'warning' },
            annotations: {
              summary: 'Traefik service requests error (4XX) increase for {{ $labels.protocol }}/{{ $labels.service }}',
            },
          },
          {
            alert: 'TraefikServiceErrors5XX',
            expr: 'sum by (service, protocol) (delta(traefik_service_requests_total{code=~"5.."}[5m])) / sum by(service, protocol) (delta(traefik_service_requests_total{code!~"(4|5).."}[5m])) > 0.1',
            'for': '10m',
            labels: { service: 'traefik', severity: 'warning' },
            annotations: {
              summary: 'Traefik service requests error (5XX) increase for {{ $labels.protocol }}/{{ $labels.service }}',
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
            alert: 'CertInvalidShortly',
            expr: '(certmanager_certificate_expiration_timestamp_seconds - time()) / 60 / 60 / 24 < 29',
            labels: { service: 'certmanager', severity: 'info' },
            annotations: {
              summary: 'Certificate will expire soon',
            },
          },
          {
            alert: 'BlockyErrorsIncreasing',
            expr: 'increase(blocky_error_total[10m]) > 10',
            labels: { service: 'blocky', severity: 'info' },
            annotations: {
              summary: 'Errors increasing on {{ $labels.pod }}',
            },
          },
          {
            alert: 'MetalLbBGPDown',
            expr: 'max_over_time(metallb_bgp_session_up[1d]) - metallb_bgp_session_up != 0',
            labels: { service: 'metallb', severity: 'warning' },
            annotations: {
              summary: 'BGP sessions down on {{ $labels.instance }}',
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
      {
        name: 'ceph',
        enabled: false,
        rules: [
          {
            alert: 'CephMdsMissingReplicas',
            expr: 'sum(ceph_mds_metadata == 1) < 2',
            'for': '5m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Insufficient replicas for storage metadata service',
            },
          },
          {
            alert: 'CephMonQuorumAtRisk',
            expr: 'count(ceph_mon_quorum_status == 1) <= (floor(count(ceph_mon_metadata) / 2) + 1)',
            'for': '5m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Storage quorum at risk',
            },
          },
          {
            alert: 'CephOSDCriticallyFull',
            expr: '(ceph_osd_metadata * on (ceph_daemon) group_right(device_class,hostname) (ceph_osd_stat_bytes_used / ceph_osd_stat_bytes)) > 0.80',
            'for': '5m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Back-end storage device is critically full ({{ $value | humanizePercentage }}) on {{ $labels.ceph_daemon }}',
            },
          },
          {
            alert: 'CephOSDFlapping',
            expr: 'changes(ceph_osd_up[5m]) > 3',
            'for': '5m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Ceph storage osd flapping on {{ $labels.ceph_daemon }}',
            },
          },
          {
            alert: 'CephOSDSlowOps',
            expr: 'ceph_healthcheck_slow_ops > 0',
            'for': '1m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Slow ops detected in ceph cluster',
            },
          },
          {
            alert: 'CephPGNotClean',
            expr: 'ceph_pg_clean != ceph_pg_total',
            'for': '1h',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Not clean PGs detected in cluster',
            },
          },
          {
            alert: 'CephPGNotActive',
            expr: 'ceph_pg_active != ceph_pg_total',
            'for': '1h',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Not active PGs detected in cluster',
            },
          },
          {
            alert: 'CephPGUndersized',
            expr: 'ceph_pg_undersized > 0',
            'for': '30m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'PGs data recovery is slow',
            },
          },
          {
            alert: 'CephPGInconsistent',
            expr: 'ceph_pg_inconsistent > 0',
            'for': '30m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Inconsistent PGs detected in cluster',
            },
          },
          {
            alert: 'CephMissingHealthStatus',
            expr: 'absent(ceph_health_status) == 1',
            'for': '10m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Missing ceph_health_status metric',
            },
          },
          {
            alert: 'CephClusterErrorState',
            expr: 'ceph_health_status > 1',
            'for': '5m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Storage cluster is in error state',
            },
          },
          {
            alert: 'CephClusterWarningState',
            expr: 'ceph_health_status == 1',
            'for': '20m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Storage cluster is in warning state',
            },
          },
          {
            alert: 'CephServiceVersionMismatch',
            expr: 'count(count by(ceph_version) ({__name__=~"^ceph_(osd|mgr|mds|mon)_metadata$"})) > 1',
            'for': '10m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'There are multiple versions of services running',
            },
          },
          {
            alert: 'CephClusterCriticallyFull',
            expr: 'ceph_cluster_total_used_raw_bytes / ceph_cluster_total_bytes > 0.75',
            'for': '30m',
            labels: { service: 'ceph', severity: 'warning' },
            annotations: {
              summary: 'Storage cluster is critically full',
            },
          },
          {
            alert: 'CephClusterReadOnly',
            expr: 'ceph_cluster_total_used_raw_bytes / ceph_cluster_total_bytes >= 0.85',
            'for': '1m',
            labels: { service: 'ceph', severity: 'critical' },
            annotations: {
              summary: 'Storage cluster is in read only mode',
            },
          },
        ],
      },
      {
        name: 'longhorn',
        rules: [
          {
            alert: 'LonghornWrongVolumeRobustness',
            expr: 'longhorn_volume_robustness > 1',
            'for': '10m',
            labels: { service: 'longhorn', severity: 'warning' },
            annotations: {
              summary: 'Volume {{ $labels.volume }} is not healthy',
            },
          },
          {
            alert: 'LonghornHighDiskUsage',
            expr: 'longhorn_disk_usage_bytes / longhorn_disk_capacity_bytes > 0.7',
            labels: { service: 'longhorn', severity: 'info' },
            annotations: {
              summary: 'High disk usage on {{ $labels.node }}',
            },
          },
          {
            alert: 'LonghornNodeDown',
            expr: 'longhorn_node_status != 1',
            labels: { service: 'longhorn', severity: 'critical' },
            annotations: {
              summary: 'Node {{ $labels.node }} is unhealthy ({{ $labels.condition }})',
            },
          },
        ],
      },
      {
        name: 'recorder',
        rules: [
          {
            alert: 'RecorderWorkersHanging',
            expr: 'recorder_workers > 0',
            'for': '30m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder worker {{ $labels.service }} is running for more than 30m',
            },
          },
          {
            alert: 'RecorderErrors',
            expr: 'delta(recorder_errors_total[5m]) > 0',
            'for': '1m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder errors observed for {{ $labels.service }} in last 5m',
            },
          },
        ],
      },
      {
        name: 'broker-ha',
        rules: [
          {
            alert: 'BrokerWrongClusterMembers',
            expr: 'broker_cluster_members != 3',
            'for': '3m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} has wrong number of cluster members',
            },
          },
          {
            alert: 'BrokerUnhealthy',
            expr: 'broker_cluster_member_health > 0',
            'for': '2m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} is unhealthy ',
            },
          },
          {
            alert: 'BrokerFromClusterQueueHigh',
            expr: 'broker_cluster_mqtt_publish_from_cluster > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} is unable to process messages from cluster',
            },
          },
          {
            alert: 'BrokerToClusterQueueHigh',
            expr: 'broker_cluster_mqtt_publish_to_cluster > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} is unable to process messages to cluster',
            },
          },
          {
            alert: 'BrokerPublishDroppedHigh',
            expr: 'broker_publish_dropped > 0',
            'for': '5m',
            labels: {
              service: 'broker-ha',
              severity: 'warning',
            },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} starts dropping publish messages',
            },
          },
          {
            alert: 'BrokerInFlightHigh',
            expr: 'broker_inflight_messages > 0',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} starts reporting in-flight messages',
            },
          },
          {
            alert: 'BrokerRetainedMessagesMismatch',
            expr: 'broker_retained_messages != scalar(max(broker_retained_messages))',
            'for': '5m',
            labels: { service: 'broker-ha', severity: 'warning' },
            annotations: {
              summary: 'Broker-ha {{ $labels.pod }} have different number of retained messages than other cluster members',
            },
          },
        ],
      },
      {
        name: 'mosquitto',
        enabled: false,
        rules: [
          {
            alert: 'MosquittoNoClients',
            expr: 'broker_clients_connected == 0',
            'for': '5m',
            labels: { service: 'mosquitto', severity: 'warning' },
            annotations: {
              summary: 'Mosquitto broker {{ $labels.pod }} has no client connected',
            },
          },
          {
            alert: 'MosquittoPublishDropped',
            expr: 'broker_load_publish_dropped_15min > 0',
            'for': '5m',
            labels: { service: 'mosquitto', severity: 'warning' },
            annotations: {
              summary: 'Mosquitto broker {{ $labels.pod }} started dropping publish messages',
            },
          },
          {
            alert: 'MosquittoMessagesSentDifferent',
            expr: 'broker_load_messages_sent_1min / avg_over_time(broker_load_messages_sent_1min[15m]) > 2 or broker_load_messages_sent_1min / avg_over_time(broker_load_messages_sent_1min[15m]) < 0.5',
            'for': '10m',
            labels: { service: 'mosquitto', severity: 'warning' },
            annotations: {
              summary: 'Mosquitto broker {{ $labels.pod }} start sending different ammount of messages ({{ $value | humanizePercentage }}) than in last 15m',
            },
          },
          {
            alert: 'MosquittoMessagesReceiveDifferent',
            expr: 'broker_load_messages_received_1min / avg_over_time(broker_load_messages_received_1min[15m]) > 2 or broker_load_messages_received_1min / avg_over_time(broker_load_messages_received_1min[15m]) < 0.5',
            'for': '10m',
            labels: { service: 'mosquitto', severity: 'warning' },
            annotations: {
              summary: 'Mosquitto broker {{ $labels.pod }} start receiving different ammount of messages ({{ $value | humanizePercentage }}) than in last 15m',
            },
          },
        ],
      },
      {
        name: 'mysql',
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
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        rules: group.rules,
      }
      for group in $.prometheus.rules
    ],
    extra_scrape_rendered:: [
      $._config.prometheus.server.extra_scrape_config[extra_scrape]
      for extra_scrape in std.objectFields($._config.prometheus.server.extra_scrape_config)
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
