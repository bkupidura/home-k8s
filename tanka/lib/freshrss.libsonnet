{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  freshrss: {
    service: s.new('freshrss',
                   { 'app.kubernetes.io/name': 'freshrss' },
                   [
                     v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'freshrss' }),
    ingress_route: $._custom.ingress_route.new('freshrss', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`rss.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'freshrss', port: 80 }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    pvc: p.new('freshrss')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '2Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('freshrss', 'home-infra', '50 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'freshrss'),
    cronjob_restore: $._custom.cronjob_restore.new('freshrss', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host freshrss --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'freshrss'),
    deployment: d.new('freshrss',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('freshrss', $._version.freshrss.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          CRON_MIN: '*/20',
                          TRUSTED_PROXY: $._config.kubernetes_internal_cidr,
                        })
                        + c.resources.withRequests({ memory: '32Mi', cpu: '30m' })
                        + c.resources.withLimits({ memory: '128Mi', cpu: '100m' })
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/api/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'freshrss' })
                + d.pvcVolumeMount('freshrss', '/var/www/FreshRSS/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.metadata.withAnnotations({ 'fluentbit.io/parser': 'nginx' })
                + d.metadata.withNamespace('home-infra'),
  },
}
