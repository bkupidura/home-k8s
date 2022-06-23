{
  local s = $.k.storage.v1,
  longhorn: {
    namespace: $.k.core.v1.namespace.new('longhorn-system'),
    helm: $._custom.helm.new('longhorn', 'https://charts.longhorn.io', $._version.longhorn.chart, 'longhorn-system', {
      defaultSettings: {
        storageOverProvisioningPercentage: 100,
        nodeDownPodDeletionPolicy: 'delete-both-statefulset-and-deployment-pod',
        replicaAutoBalance: 'best-effort',
        concurrentAutomaticEngineUpgradePerNodeLimit: 1,
      },
      annotations: {
        'prometheus.io/scrape': 'true',
        'prometheus.io/port': '9500',
      },
    }),
    storage_class_without_snapshot: s.storageClass.new('longhorn-standard')
                                    + s.storageClass.withProvisioner('driver.longhorn.io')
                                    + s.storageClass.withAllowVolumeExpansion(true)
                                    + s.storageClass.withMountOptions(['noatime'])
                                    + s.storageClass.withParameters({
                                      numberOfReplicas: '2',
                                      staleReplicaTimeout: '2880',
                                      fromBackup: '',
                                    }),
    storage_class_with_snapshot: s.storageClass.new('longhorn-standard-with-snapshots')
                                 + s.storageClass.withProvisioner('driver.longhorn.io')
                                 + s.storageClass.withAllowVolumeExpansion(true)
                                 + s.storageClass.withMountOptions(['noatime'])
                                 + s.storageClass.withParameters({
                                   numberOfReplicas: '2',
                                   staleReplicaTimeout: '2880',
                                   fromBackup: '',
                                   recurringJobs: '[ { "name":"snap", "task":"snapshot", "cron":"15 */6 * * *", "retain": 8 } ]',
                                 }),
    ingress_route: $._custom.ingress_route.new('longhorn', 'longhorn-system', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`storage.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'longhorn-frontend', port: 80, namespace: 'longhorn-system' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
  },
}
