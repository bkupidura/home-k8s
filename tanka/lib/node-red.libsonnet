{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  node_red: {
    pvc: p.new('node-red')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route: $._custom.ingress_route.new('node-red', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`node-red.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'node-red', port: 1880, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('node-red', 'smart-home', '10 04 * * *', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
    )], 'node-red'),
    cronjob_restore: $._custom.cronjob_restore.new('node-red', 'smart-home', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host node-red --target .', std.extVar('secrets').restic.repo.default)]
    )], 'node-red'),
    helm: $._custom.helm.new('node-red', 'https://k8s-at-home.com/charts/', $._version.node_red.chart, 'smart-home', {
      controller: {
        replicas: if $._config.restore then 0 else 1,
      },
      resources: {
        requests: { memory: '384Mi', cpu: '500m' },
        limits: { memory: '384Mi', cpu: '500m' },
      },
      affinity: {
        podAntiAffinity: {
          preferredDuringSchedulingIgnoredDuringExecution: [
            {
              weight: 1,
              podAffinityTerm: {
                labelSelector: {
                  matchExpressions: [
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['home-assistant', 'zigbee2mqtt'] },
                  ],
                },
                topologyKey: 'kubernetes.io/hostname',
              },
            },
          ],
        },
      },
      env: { TZ: $._config.tz },
      image: { repository: $._version.node_red.repo, tag: $._version.node_red.tag },
      persistence: {
        data: { enabled: true, existingClaim: 'node-red' },
      },
      ingress: { main: { enabled: false } },
      podSecurityContext: { fsGroup: 1000 },
      probes: {
        liveness: {
          enabled: true,
          custom: true,
          spec: {
            periodSeconds: 10,
            failureThreshold: 3,
            initialDelaySeconds: 60,
            httpGet: { path: '/dead-man-switch', port: 1880 },
          },
        },
      },
    }),
  },
}
