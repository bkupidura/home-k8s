{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  grafana: {
    pvc: p.new('grafana')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route: $._custom.ingress_route.new('grafana', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`grafana.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'grafana', port: 80, namespace: 'home-infra' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('grafana', 'home-infra', '30 04 * * *', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
    )], 'grafana'),
    cronjob_restore: $._custom.cronjob_restore.new('grafana', 'home-infra', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host grafana --target .', std.extVar('secrets').restic.repo.default)]
    )], 'grafana'),
    helm: $._custom.helm.new('grafana', 'https://grafana.github.io/helm-charts', $._version.grafana.chart, 'home-infra', {
      replicas: if $._config.restore then '0' else '1',
      resources: {
        requests: { memory: '32Mi' },
        limits: { memory: '64Mi' },
      },
      image: { repository: $._version.grafana.repo, tag: $._version.grafana.tag },
      ingress: { enabled: false },
      deploymentStrategy: { type: 'Recreate' },
      persistence: { enabled: true, existingClaim: 'grafana' },
      adminUser: 'admin',
      adminPassword: std.extVar('secrets').grafana.password,
      'grafana.ini': {
        server: { domain: std.format('grafana.%s', std.extVar('secrets').domain), root_url: 'https://%(domain)s/' },
        security: { allow_embedding: true },
        auth: { disable_login_form: true },
        'auth.generic_oauth': {
          allow_sign_up: true,
          api_url: 'http://authelia.home-infra:9091/api/oidc/userinfo',
          token_url: 'http://authelia.home-infra:9091/api/oidc/token',
          auth_url: std.format('https://auth.%s/api/oidc/authorize', std.extVar('secrets').domain),
          client_id: 'grafana',
          client_secret: std.extVar('secrets').authelia.oidc.client.grafana.secret,
          enabled: true,
          name: 'Authelia',
          role_attribute_path: "contains(groups[*], 'admin') && 'Admin' || 'Viewer'",
          scopes: 'openid profile email groups',
        },
      },
      datasources: {
        'datasources.yaml': {
          apiVersion: 1,
          datasources: [
            { name: 'Prometheus', type: 'prometheus', url: 'http://prometheus-server.home-infra', access: 'proxy', isDefault: true },
          ],
        },
      },
    }),
  },
}
