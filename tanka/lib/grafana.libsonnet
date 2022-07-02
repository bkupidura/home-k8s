{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  grafana: {
    pvc: p.new('grafana')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    service: s.new(
               'grafana',
               { 'app.kubernetes.io/name': 'grafana' },
               [v1.servicePort.withPort(3000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'grafana' }),
    ingress_route: $._custom.ingress_route.new('grafana', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`grafana.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'grafana', port: 3000, namespace: 'home-infra' }],
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
    config: v1.configMap.new('grafana-config', {
              'grafana.ini': std.manifestIni({
                sections: {
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
              }),
              'datasources.yaml': std.manifestYamlDoc({
                apiVersion: 1,
                datasources: [
                  { name: 'Prometheus', type: 'prometheus', url: 'http://prometheus-server.home-infra', access: 'proxy', isDefault: true },
                ],
              }),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('grafana',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('grafana', $._version.grafana.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(3000, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          GF_PATHS_DATA: '/var/lib/grafana',
                          GF_PATHS_LOGS: '/var/log/grafana',
                          GF_PATHS_PLUGINS: '/var/lib/grafana/plugins',
                          GF_PATHS_PROVISIONING: '/etc/grafana/provisioning',
                          GF_SECURITY_ADMIN_USER: 'admin',
                          GF_SECURITY_ADMIN_PASSWORD: std.extVar('secrets').grafana.password,
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('grafana-config', '/etc/grafana/grafana.ini', false) + v1.volumeMount.withSubPath('grafana.ini'),
                          v1.volumeMount.new('grafana-config', '/etc/grafana/provisioning/datasources/datasources.yaml', false) + v1.volumeMount.withSubPath('datasources.yaml'),
                        ])
                        + c.resources.withRequests({ memory: '32Mi' })
                        + c.resources.withLimits({ memory: '64Mi' })
                        + c.readinessProbe.httpGet.withPath('/api/health')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(20)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/api/health')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'grafana' })
                + d.pvcVolumeMount('grafana', '/var/lib/grafana', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withVolumes(v1.volume.fromConfigMap('grafana-config', 'grafana-config'))
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
