{
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
