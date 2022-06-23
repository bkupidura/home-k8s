{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  home_assistant: {
    pvc: p.new('home-assistant')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '5Gi' }),
    ingress_route: $._custom.ingress_route.new('home-assistant', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`ha.%s`) && (Path(`/api/websocket`) || Path(`/auth/token`) || Path(`/api/ios/config`) || PathPrefix(`/api/webhook/`))', std.extVar('secrets').domain),
        services: [{ name: 'home-assistant', port: 8123, namespace: 'smart-home' }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
      {
        kind: 'Rule',
        match: std.format('Host(`ha.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'home-assistant', port: 8123, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('home-assistant', 'smart-home', '20 04 * * *', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
    )], 'home-assistant'),
    cronjob_restore: $._custom.cronjob_restore.new('home-assistant', 'smart-home', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host home-assistant --target .', std.extVar('secrets').restic.repo.default)]
    )], 'home-assistant'),
    helm: $._custom.helm.new('home-assistant', 'https://k8s-at-home.com/charts/', $._version.home_assistant.chart, 'smart-home', {
      controller: {
        replicas: if $._config.restore then 0 else 1,
      },
      resources: {
        requests: { memory: '512Mi', cpu: '300m' },
        limits: { memory: '512Mi', cpu: '300m' },
      },
      affinity: {
        podAntiAffinity: {
          preferredDuringSchedulingIgnoredDuringExecution: [
            {
              weight: 1,
              podAffinityTerm: {
                labelSelector: {
                  matchExpressions: [
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['node-red', 'zigbee2mqtt'] },
                  ],
                },
                topologyKey: 'kubernetes.io/hostname',
              },
            },
          ],
        },
      },
      env: {
        TZ: $._config.tz,
      },
      image: { repository: $._version.home_assistant.repo, tag: $._version.home_assistant.tag },
      persistence: {
        config: { enabled: true, existingClaim: 'home-assistant' },
      },
      service: {
        main: {
          ports: {
            http: { enabled: true, port: 8123 },
          },
        },
        'vip-udp': {
          enabled: true,
          type: 'LoadBalancer',
          loadBalancerIP: $._config.vip.home_assistant,
          externalTrafficPolicy: 'Local',
          annotations: { 'metallb.universe.tf/allow-shared-ip': $._config.vip.home_assistant },
          ports: {
            'shelly-coap': { enabled: true, port: 5683, protocol: 'UDP' },
          },
        },
        'vip-tcp': {
          enabled: true,
          type: 'LoadBalancer',
          loadBalancerIP: $._config.vip.home_assistant,
          externalTrafficPolicy: 'Local',
          annotations: { 'metallb.universe.tf/allow-shared-ip': $._config.vip.home_assistant },
          ports: {
            sonos: { enabled: true, port: 1400, protocol: 'TCP' },
          },
        },
      },
      ingress: { main: { enabled: false } },
      probes: {
        liveness: {
          enabled: true,
          custom: true,
          spec: {
            periodSeconds: 15,
            failureThreshold: 5,
            initialDelaySeconds: 120,
            timeoutSeconds: 5,
            httpGet: { path: '/healthz', port: 8123 },
          },
        },
      },
    }),
  },
}
