{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  unifi: {
    pvc: p.new('unifi')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '5Gi' }),
    ingress_route_https: $._custom.ingress_route.new('unifi', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`unifi.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'unifi', port: 443, namespace: 'home-infra', scheme: 'https' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
    ingress_route_http: $._custom.ingress_route.new('unifi-http', 'home-infra', ['web'], [
      {
        kind: 'Rule',
        match: std.format('Host(`unifi.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'unifi', port: 80, namespace: 'home-infra', scheme: 'http' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], false),
    cronjob_backup: $._custom.cronjob_backup.new('unifi', 'home-infra', '00 04 * * *', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
    )], 'unifi'),
    cronjob_restore: $._custom.cronjob_restore.new('unifi', 'home-infra', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host unifi --target .', std.extVar('secrets').restic.repo.default)]
    )], 'unifi'),
    helm: $._custom.helm.new('unifi', 'https://k8s-at-home.com/charts/', $._version.unifi.chart, 'home-infra', {
      controller: {
        replicas: if $._config.restore then 0 else 1,
      },
      resources: {
        requests: { memory: '500Mi' },
        limits: { memory: '1Gi' },
      },
      env: { TZ: $._config.tz, JVM_MAX_HEAP_SIZE: '384M', JVM_MAX_THREAD_STACK_SIZE: '1M' },
      image: { repository: $._version.unifi.repo, tag: $._version.unifi.tag },
      persistence: {
        data: { enabled: true, existingClaim: 'unifi' },
      },
      service: {
        main: {
          ports: {
            http: { enabled: true, port: 443 },
            controller: { enabled: true, port: 80 },
            stun: { enabled: false },
            discovery: { enabled: false },
            syslog: { enabled: false },
            'portal-http': { enabled: false },
            'portal-https': { enabled: false },
            speedtest: { enabled: false },
          },
        },
      },
    }),
  },
}
