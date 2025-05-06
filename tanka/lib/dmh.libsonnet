{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'dmh',
        rules: [
          {
            alert: 'DMHActionExecuted',
            expr: 'delta(dmh_actions{name="dmh", processed="0"}[15m]) < 0',
            labels: { service: 'dmh', severity: 'warning' },
            annotations: {
              summary: 'Some dead-man-hand actions were executed or deleted on {{ $labels.pod }}',
            },
          },
        ],
      },
    ],
  },
  dmh: {
    restore:: $._config.restore,
    pvc: p.new('dmh')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '50Mi' }),
    ingress_route_ssl: $._custom.ingress_route.new('dmh', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`dmh.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'dmh', port: 8080, namespace: 'self-hosted' }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    cronjob_backup: $._custom.cronjob_backup.new('dmh', 'self-hosted', '05 05 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'dmh'),
    cronjob_restore: $._custom.cronjob_restore.new('dmh', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'dmh'),
    service: s.new('dmh', { 'app.kubernetes.io/name': 'dmh' }, [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'dmh' }),
    config: v1.configMap.new('dmh-config', {
              'config.yaml': std.manifestYamlDoc({
                components: ['dmh'],
                state: { file: '/data/state.json' },
                remote_vault: {
                  client_uuid: std.extVar('secrets').dmh.remote_vault.client_uuid,
                  url: std.extVar('secrets').dmh.remote_vault.url,
                },
                action: { process_unit: 'hour' },
                execute: {
                  plugin: {
                    bulksms: { routing_group: 'premium', token: { id: std.extVar('secrets').dmh.execute.plugin.bulksms.token.id, secret: std.extVar('secrets').dmh.execute.plugin.bulksms.token.secret } },
                    mail: {
                      username: std.extVar('secrets').smtp.username,
                      password: std.extVar('secrets').smtp.password,
                      server: std.extVar('secrets').smtp.server,
                      from: std.format('dmh@%s', std.extVar('secrets').domain),
                      tls_policy: 'tls_mandatory',
                    },
                  },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('self-hosted'),
    deployment: d.new('dmh',
                      if $.dmh.restore then 0 else 1,
                      [
                        c.new('dmh', $._version.dmh.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8080, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          DMH_CONFIG_FILE: '/config/config.yaml',
                        })
                        + c.resources.withRequests({ memory: '16Mi', cpu: '20m' })
                        + c.resources.withLimits({ memory: '32Mi', cpu: '40m' })
                        + c.readinessProbe.httpGet.withPath('/ready')
                        + c.readinessProbe.httpGet.withPort(8080)
                        + c.readinessProbe.withInitialDelaySeconds(5)
                        + c.readinessProbe.withPeriodSeconds(5)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort(8080)
                        + c.livenessProbe.withInitialDelaySeconds(5)
                        + c.livenessProbe.withPeriodSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'dmh' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.configVolumeMount('dmh-config', '/config/', {})
                + d.pvcVolumeMount('dmh', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('self-hosted')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                }),
  },
}
