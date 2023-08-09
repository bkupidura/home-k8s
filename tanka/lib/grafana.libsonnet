{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  grafana: {
    pvc: p.new('grafana')
         + p.metadata.withNamespace('monitoring')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '128Mi' }),
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
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('grafana', 'monitoring', '30 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'grafana'),
    cronjob_restore: $._custom.cronjob_restore.new('grafana', 'monitoring', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host grafana --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'grafana'),
    config: v1.configMap.new('grafana-config', {
              'grafana.ini': std.manifestIni({
                sections: {
                  server: { domain: std.format('grafana.%s', std.extVar('secrets').domain), root_url: 'https://%(domain)s/' },
                  security: { allow_embedding: true },
                  auth: { disable_login_form: true, oauth_allow_insecure_email_lookup: true },
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
            })
            + v1.configMap.metadata.withNamespace('monitoring'),
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
                        ])
                        + c.resources.withRequests({ memory: '64Mi' })
                        + c.resources.withLimits({ memory: '128Mi' })
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
                + d.spec.template.spec.withVolumes(v1.volume.fromConfigMap('grafana-config', 'grafana-config'))
                + d.pvcVolumeMount('grafana', '/var/lib/grafana', false, {})
                + d.spec.template.spec.withInitContainers(
                  c.new('chown-data', $._version.ubuntu.image)
                  + c.withImagePullPolicy('IfNotPresent')
                  + c.withCommand(['chown', '-R', '472:472', '/var/lib/grafana'])
                  + c.withVolumeMounts([
                    v1.volumeMount.new('grafana', '/var/lib/grafana', false),
                  ])
                  + c.securityContext.withRunAsNonRoot(false)
                  + c.securityContext.withRunAsUser(0)
                )
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('monitoring')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
