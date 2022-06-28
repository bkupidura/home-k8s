{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  prometheus+: {
    rules+:: [
      {
        name: 'restic',
        rules: [
          {
            alert: 'ResticNoNewBackup',
            expr: 'delta(rest_server_blob_write_bytes_total{type="snapshots"}[5d]) <= 0',
            'for': '1d',
            labels: { service: 'restic', severity: 'warning' },
            annotations: {
              summary: 'No new backups found for repo {{ $labels.repo }}',
            },
          },
        ],
      },
    ],
  },
  restic_server: {
    _custom:: {
      cronjob_backup:: {
        new(name, namespace, schedule, command): $._custom.cronjob.new(name + '-backup', namespace, schedule, [
                                                   $.k.core.v1.container.new('backup', $._version.restic.image)
                                                   + $.k.core.v1.container.withVolumeMounts([
                                                     $.k.core.v1.volumeMount.new('data', '/data', false),
                                                   ])
                                                   + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName('restic-secrets'))
                                                   + $.k.core.v1.container.withCommand(command),
                                                 ])
                                                 + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname(name)
                                                 + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                   $.k.core.v1.volume.fromHostPath('data', '/srv/restic') + v1.volume.hostPath.withType('Directory'),
                                                 ])
                                                 + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms(
                                                   { matchExpressions: [{ key: 'restic_controller', operator: 'In', values: ['true'] }] },
                                                 ),
      },
      cronjob_restore:: {
        new(name, namespace, command): $._custom.cronjob.new(name + '-restore', namespace, '0 0 * * *', [
                                         $.k.core.v1.container.new('restore', $._version.restic.image)
                                         + $.k.core.v1.container.withVolumeMounts([
                                           $.k.core.v1.volumeMount.new('data', '/data', false),
                                         ])
                                         + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName('restic-secrets'))
                                         + $.k.core.v1.container.withCommand(command),
                                       ])
                                       + $.k.batch.v1.cronJob.spec.withSuspend(true)
                                       + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname(name)
                                       + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                         $.k.core.v1.volume.fromHostPath('data', '/srv/restic') + v1.volume.hostPath.withType('Directory'),
                                       ])
                                       + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms(
                                         { matchExpressions: [{ key: 'restic_controller', operator: 'In', values: ['true'] }] },
                                       ),
      },
    },
    user:: [
      std.format('create_user %(username)s %(password)s', { username: username, password: std.extVar('secrets').restic.server.user[username] })
      for username in std.objectFields(std.extVar('secrets').restic.server.user)
    ],
    service: s.new(
               'restic-server',
               { 'app.kubernetes.io/name': 'restic-server' },
               [v1.servicePort.withPort(8000) + v1.servicePort.withName('restic-server')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'restic-server' }),
    ingress_route: $._custom.ingress_route.new('restic-server', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`restic.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'restic-server', port: 8000 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $.restic_server._custom.cronjob_backup.new('restic-server', 'home-infra', '00 03 * * *', ['/bin/sh', '-ec', std.join('\n', ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.server)])]),
    cronjob_restore: $.restic_server._custom.cronjob_restore.new('restic-server', 'home-infra', ['/bin/sh', '-ec', std.join('\n', ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host restic-server --target .', std.extVar('secrets').restic.repo.server)])]),
    deployment: d.new('restic-server',
                      1,
                      [
                        c.new('restic-server', $._version.restic.server)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(8000, 'http'))
                        + c.withVolumeMounts([
                          v1.volumeMount.new('data', '/data', false),
                        ])
                        + c.withCommand([
                          '/bin/sh',
                          '-ec',
                          std.format('touch /data/.htaccess\n%s\n/entrypoint.sh', std.join('\n', $.restic_server.user)),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          OPTIONS: '--private-repos --prometheus --prometheus-no-auth',
                        })
                        + c.resources.withLimits({ memory: '64Mi', cpu: '200m' })
                        + c.resources.withRequests({ memory: '64Mi', cpu: '200m' }),
                      ],
                      { 'app.kubernetes.io/name': 'restic-server' })
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8000',
                })
                + d.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms(
                  { matchExpressions: [{ key: 'restic_controller', operator: 'In', values: ['true'] }] },
                )
                + d.spec.template.spec.withVolumes([
                  $.k.core.v1.volume.fromHostPath('data', '/srv/restic') + v1.volume.hostPath.withType('Directory'),
                ]),
  },
}
