{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  logging+: {
    rules+:: [
      {
        name: 'vaultwarden',
        interval: '1m',
        rules: [
          {
            record: 'vaultwarden:failed_login:5m',
            expr: 'count_over_time({kubernetes_container_name="vaultwarden"} |~ "(?i)username or password is incorrect"[5m])',
          },
        ],
      },
    ],
  },
  monitoring+: {
    rules+:: [
      {
        name: 'vaultwarden',
        rules: [
          {
            alert: 'VaultwardenFailedLogin',
            expr: 'vaultwarden:failed_login:5m > 1',
            labels: { service: 'vaultwarden', severity: 'info' },
            annotations: {
              summary: 'Failed login attempts on {{ $labels.kubernetes_pod_name }}',
            },
          },
        ],
      },
    ],
  },
  authelia+: {
    access_control+: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('vaultwarden.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:admin',
          policy: 'two_factor',
        },
      },
    ],
  },
  vaultwarden: {
    restore:: $._config.restore,
    pvc: p.new('vaultwarden')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '512Mi' }),
    cronjob_backup: $._custom.cronjob.new('vaultwarden-backup',
                                          'self-hosted',
                                          '10 05 * * *',
                                          [
                                            c.new('backup', $._version.ubuntu.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('ssh', '/root/.ssh', false),
                                              v1.volumeMount.new('vaultwarden-data', '/data', false),
                                            ])
                                            + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'apt update || true',
                                                'apt install -y restic sqlite openssh-client',
                                                'cd /data',
                                                'sqlite3 db.sqlite3 ".backup db-backup-$(date +%d-%m-%YT%H:%M:%S).dump"',
                                                std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection),
                                                'find /data -type f -name db-backup-\\*.dump -mtime +60 -delete',
                                              ]),
                                            ]),
                                          ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('vaultwarden')
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                      v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                      v1.volume.fromPersistentVolumeClaim('vaultwarden-data', 'vaultwarden'),
                    ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                      v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                      + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                        { key: 'app.kubernetes.io/name', operator: 'In', values: ['vaultwarden'] }
                      )
                    ),
    cronjob_restore: $._custom.cronjob_restore.new('vaultwarden', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host vaultwarden --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'vaultwarden'),
    ingress_route: $._custom.ingress_route.new('vaultwarden', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`vaultwarden.%s`) && PathPrefix(`/admin`)', std.extVar('secrets').domain),
        services: [{ name: 'vaultwarden', port: 80, namespace: 'self-hosted' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
      {
        kind: 'Rule',
        match: std.format('Host(`vaultwarden.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'vaultwarden', port: 80, namespace: 'self-hosted' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    service: s.new('vaultwarden', { 'app.kubernetes.io/name': 'vaultwarden' }, [
               v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
             ])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'vaultwarden' }),
    deployment: d.new('vaultwarden',
                      if $.vaultwarden.restore then 0 else 1,
                      [
                        c.new('vaultwarden', $._version.vaultwarden.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          DISABLE_ADMIN_TOKEN: 'true',
                          DOMAIN: std.format('https://vaultwarden.%s', std.extVar('secrets').domain),
                        })
                        + c.resources.withRequests({ memory: '128Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '128Mi', cpu: '50m' })
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/alive')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'vaultwarden' })
                + d.pvcVolumeMount('vaultwarden', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('self-hosted')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
