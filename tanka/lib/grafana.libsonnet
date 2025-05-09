{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  grafana: {
    service: s.new(
               'grafana',
               { 'app.kubernetes.io/name': 'grafana' },
               [v1.servicePort.withPort(3000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('monitoring')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'grafana' }),
    ingress_route: $._custom.ingress_route.new('grafana', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`grafana.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'grafana', port: 3000, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    config: v1.configMap.new('grafana-config', {
              'grafana.ini': std.manifestIni({
                sections: {
                  server: { domain: std.format('grafana.%s', std.extVar('secrets').domain), root_url: 'https://%(domain)s/' },
                  security: { allow_embedding: true },
                  database: { type: 'mysql', host: 'mariadb.home-infra', name: 'grafana', user: 'grafana', password: std.extVar('secrets').grafana.db.password },
                  auth: { disable_login_form: true, oauth_allow_insecure_email_lookup: true },
                  log: { level: 'info' },
                  'auth.generic_oauth': {
                    allow_sign_up: true,
                    api_url: 'http://authelia.home-infra:9091/api/oidc/userinfo',
                    token_url: 'http://authelia.home-infra:9091/api/oidc/token',
                    auth_url: std.format('https://auth.%s/api/oidc/authorize', std.extVar('secrets').domain),
                    client_id: 'grafana',
                    client_secret: std.extVar('secrets').grafana.oidc.client_secret,
                    enabled: true,
                    name: 'Authelia',
                    role_attribute_path: "contains(groups[*], 'admin') && 'Admin' || 'Viewer'",
                    scopes: 'openid profile email groups',
                    login_attribute_path: 'preferred_username',
                    groups_attribute_path: 'groups',
                    name_attribute_path: 'name',
                  },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('monitoring'),
    deployment: d.new('grafana',
                      1,
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
                        ])
                        + c.resources.withRequests({ memory: '128Mi' })
                        + c.resources.withLimits({ memory: '196Mi' })
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
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.spec.template.spec.withVolumes(v1.volume.fromConfigMap('grafana-config', 'grafana-config'))
                + d.spec.strategy.withType('RollingUpdate')
                + d.metadata.withNamespace('monitoring')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5)
                + d.spec.template.metadata.withAnnotations({
                  'fluentbit.io/parser': 'logfmt',
                }),
  },
}
