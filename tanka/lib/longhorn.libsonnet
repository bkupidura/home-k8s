{
  local s = $.k.storage.v1,
  monitoring+: {
    rules+:: [
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
            expr: 'longhorn_disk_usage_bytes / longhorn_disk_capacity_bytes > 0.9',
            labels: { service: 'longhorn', severity: 'info' },
            annotations: {
              summary: 'High disk usage on {{ $labels.node }}',
            },
          },
          {
            alert: 'LonghornNodeDown',
            expr: 'longhorn_node_status{condition=~"(ready|schedulable|allowScheduling)"} != 1',
            labels: { service: 'longhorn', severity: 'critical' },
            annotations: {
              summary: 'Node {{ $labels.node }} is unhealthy ({{ $labels.condition }})',
            },
          },
          {
            alert: 'LonghornWrongDiskStatus',
            expr: 'longhorn_disk_status != 1',
            labels: { service: 'longhorn', severity: 'warning' },
            annotations: {
              summary: 'Disk {{ $labels.disk }} on {{ $labels.node }} is {{ $labels.condition }} ({{ $labels.condition_reason }})',
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
            std.format('storage.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:admin',
          policy: 'two_factor',
        },
      },
    ],
  },
  storage+: {
    class_without_snapshot: s.storageClass.new('longhorn-standard')
                            + s.storageClass.withProvisioner('driver.longhorn.io')
                            + s.storageClass.withAllowVolumeExpansion(true)
                            + s.storageClass.withMountOptions(['noatime'])
                            + s.storageClass.withParameters({
                              numberOfReplicas: '3',
                              staleReplicaTimeout: '360',
                              fromBackup: '',
                            }),
    class_with_snapshot: s.storageClass.new('longhorn-standard-with-snapshots')
                         + s.storageClass.withProvisioner('driver.longhorn.io')
                         + s.storageClass.withAllowVolumeExpansion(true)
                         + s.storageClass.withMountOptions(['noatime'])
                         + s.storageClass.withParameters({
                           numberOfReplicas: '3',
                           staleReplicaTimeout: '360',
                           fromBackup: '',
                           recurringJobs: '[ { "name":"snap", "task":"snapshot", "cron":"15 */3 * * *", "retain": 8 } ]',
                         }),
    class_with_encryption: s.storageClass.new('longhorn-encrypted')
                           + s.storageClass.withProvisioner('driver.longhorn.io')
                           + s.storageClass.withAllowVolumeExpansion(true)
                           + s.storageClass.withMountOptions(['noatime'])
                           + s.storageClass.withParameters({
                             numberOfReplicas: '3',
                             staleReplicaTimeout: '360',
                             fromBackup: '',
                             recurringJobs: '[ { "name":"snap", "task":"snapshot", "cron":"15 */3 * * *", "retain": 8 } ]',
                             encrypted: 'true',
                             'csi.storage.k8s.io/provisioner-secret-name': 'longhorn-encryption-global',
                             'csi.storage.k8s.io/provisioner-secret-namespace': 'longhorn-system',
                             'csi.storage.k8s.io/node-publish-secret-name': 'longhorn-encryption-global',
                             'csi.storage.k8s.io/node-publish-secret-namespace': 'longhorn-system',
                             'csi.storage.k8s.io/node-stage-secret-name': 'longhorn-encryption-global',
                             'csi.storage.k8s.io/node-stage-secret-namespace': 'longhorn-system',
                           }),
  },
  longhorn: {
    namespace: $.k.core.v1.namespace.new('longhorn-system'),
    secret_encryption: $.k.core.v1.secret.new('longhorn-encryption-global', {
                         CRYPTO_KEY_VALUE: std.base64(std.extVar('secrets').longhorn.encryption.global),
                         CRYPTO_KEY_PROVIDER: std.base64('secret'),
                       })
                       + $.k.core.v1.secret.metadata.withNamespace('longhorn-system'),
    helm: $._custom.helm.new('longhorn', 'longhorn', 'https://charts.longhorn.io', $._version.longhorn.chart, 'longhorn-system', {
      defaultSettings: {
        storageOverProvisioningPercentage: 100,
        nodeDownPodDeletionPolicy: 'delete-both-statefulset-and-deployment-pod',
        replicaAutoBalance: 'best-effort',
        concurrentAutomaticEngineUpgradePerNodeLimit: 1,
        orphanAutoDeletion: true,
      },
      annotations: {
        'prometheus.io/scrape': 'true',
        'prometheus.io/port': '9500',
      },
    }),
    ingress_route: $._custom.ingress_route.new('longhorn', 'longhorn-system', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`storage.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'longhorn-frontend', port: 80, namespace: 'longhorn-system' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
  },
}
