{
  prometheus+: {
    rules+:: [
      {
        name: 'ceph',
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
    ],
  },
  rook_ceph: {
    namespace: $.k.core.v1.namespace.new('rook-ceph'),
    config: $.k.core.v1.configMap.new('rook-config-override', { config: '' })
            + $.k.core.v1.configMap.metadata.withNamespace('rook-ceph'),
    helm_rook: $._custom.helm.new('rook-ceph', 'https://charts.rook.io/release', $._version.ceph.chart, 'rook-ceph', {
      csi: {
        csiRBDProvisionerResource: [
          {
            name: 'csi-provisioner',
            resource: {
              requests: { memory: '32Mi' },
              limits: { memory: '64Mi' },
            },
          },
        ],
        csiRBDPluginResource: [
          {
            name: 'csi-rbdplugin',
            resource: {
              requests: { memory: '64Mi' },
              limits: { memory: '128Mi' },
            },
          },
        ],
        csiCephFSProvisionerResource: [
          {
            name: 'csi-provisioner',
            resource: {
              requests: { memory: '32Mi' },
              limits: { memory: '64Mi' },
            },
          },
        ],
        csiCephFSPluginResource: [
          {
            name: 'csi-cephfsplugin',
            resource: {
              requests: { memory: '64Mi' },
              limits: { memory: '128Mi' },
            },
          },
        ],
      },
      resources: {
        limits: { cpu: '600m', memory: '256Mi' },
        requests: { cpu: '300m', memory: '128Mi' },
      },
    }),
    helm_cluster: $._custom.helm.new('rook-ceph-cluster', 'https://charts.rook.io/release', $._version.ceph.chart, 'rook-ceph', {
      toolbox: {
        enabled: false,
        resources: {
          limits: { cpu: '60m', memory: '32Mi' },
          requests: { cpu: '30m', memory: '16Mi' },
        },
      },
      cephClusterSpec: {
        cephVersion: {
          image: $._version.ceph.image,
        },
        mgr: {
          count: 1,
        },
        resources: {
          mon: {
            limits: { cpu: '250m', memory: '1280Mi' },
            requests: { cpu: '150m', memory: '512Mi' },
          },
          mgr: {
            limits: { cpu: '220m', memory: '768Mi' },
            requests: { cpu: '110m', memory: '512Mi' },
          },
          osd: {
            limits: { cpu: '300m', memory: '2Gi' },
            requests: { cpu: '150m', memory: '512Mi' },
          },
          crashcollector: {
            limits: { cpu: '50m', memory: '32Mi' },
            requests: { cpu: '10m', memory: '16Mi' },
          },
        },
        dashboard: {
          enabled: true,
        },
        crashCollector: {
          disable: true,
          daysToRetain: 30,
        },
      },
      cephBlockPools: [
        {
          name: 'ceph-blockpool',
          spec: {
            failureDomain: 'host',
            replicated: {
              size: 3,
            },
          },
          storageClass: {
            enabled: true,
            name: 'ceph-block',
            isDefault: false,
            reclaimPolicy: 'Delete',
            allowVolumeExpansion: true,
            parameters: {
              imageFormat: '2',
              imageFeatures: 'layering',
              'csi.storage.k8s.io/provisioner-secret-name': 'rook-csi-rbd-provisioner',
              'csi.storage.k8s.io/provisioner-secret-namespace': 'rook-ceph',
              'csi.storage.k8s.io/controller-expand-secret-name': 'rook-csi-rbd-provisioner',
              'csi.storage.k8s.io/controller-expand-secret-namespace': 'rook-ceph',
              'csi.storage.k8s.io/node-stage-secret-name': 'rook-csi-rbd-node',
              'csi.storage.k8s.io/node-stage-secret-namespace': 'rook-ceph',
              'csi.storage.k8s.io/fstype': 'ext4',
            },
          },
        },
      ],
      cephFileSystems: [
        {
          name: 'ceph-filesystem',
          spec: {
            metadataPool: {
              failureDomain: 'host',
              replicated: {
                size: 3,
              },
            },
            dataPools: [
              {
                failureDomain: 'host',
                replicated: {
                  size: 3,
                },
              },
            ],
            metadataServer: {
              activeCount: 1,
              activeStandby: true,
              placement: {
                podAntiAffinity: {
                  preferredDuringSchedulingIgnoredDuringExecution: [
                    {
                      weight: 1,
                      podAffinityTerm: {
                        labelSelector: {
                          matchExpressions: [
                            {
                              key: 'app.kubernetes.io/name',
                              operator: 'In',
                              values: ['ceph-mds'],
                            },
                          ],
                          topologyKey: 'kubernetes.io/hostname',
                        },
                      },
                    },
                  ],
                },
              },
            },
          },
          storageClass: {
            enabled: true,
            isDefault: false,
            name: 'ceph-filesystem',
            reclaimPolicy: 'Delete',
            allowVolumeExpansion: true,
            parameters: {
              'csi.storage.k8s.io/provisioner-secret-name': 'rook-csi-cephfs-provisioner',
              'csi.storage.k8s.io/provisioner-secret-namespace': 'rook-ceph',
              'csi.storage.k8s.io/controller-expand-secret-name': 'rook-csi-cephfs-provisioner',
              'csi.storage.k8s.io/controller-expand-secret-namespace': 'rook-ceph',
              'csi.storage.k8s.io/node-stage-secret-name': 'rook-csi-cephfs-node',
              'csi.storage.k8s.io/node-stage-secret-namespace': 'rook-ceph',
              'csi.storage.k8s.io/fstype': 'ext4',
            },
          },
        },
      ],
      cephObjectStores: {},
    }),
  },
}
