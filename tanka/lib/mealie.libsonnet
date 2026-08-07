{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  mealie: {
    restore:: $._config.restore,
    pvc: p.new('mealie')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    cronjob_backup: $._custom.cronjob.new('mealie-backup',
                                          'self-hosted',
                                          '15 05 * * *',
                                          [
                                            c.new('backup', $._version.restic.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('ssh', '/root/.ssh', false),
                                              v1.volumeMount.new('data', '/data', false),
                                            ])
                                            + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'cd /data',
                                                'restic --verbose backup .',
                                              ]),
                                            ]),
                                          ],
                                          [
                                            c.new('pre-backup', $._version.ubuntu.image)
                                            + c.withVolumeMounts([
                                              v1.volumeMount.new('data', '/data', false),
                                            ])
                                            + c.withCommand([
                                              '/bin/sh',
                                              '-ec',
                                              std.join('\n', [
                                                'apt-get update -qq',
                                                'apt-get install -y --no-install-recommends -qq sqlite3',
                                                'cd /data',
                                                'sqlite3 mealie.db ".backup mealie-backup-$(date +%d-%m-%YT%H:%M:%S).sqlite3"',
                                                'find /data -type f -name mealie-backup-\\*.sqlite3 -mtime +30 -delete',
                                              ]),
                                            ]),
                                          ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname('mealie')
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                      v1.volume.fromSecret('ssh', 'restic-ssh-default') + $.k.core.v1.volume.secret.withDefaultMode(256),
                      v1.volume.fromPersistentVolumeClaim('data', 'mealie'),
                    ])
                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                      v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                      + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                        { key: 'app.kubernetes.io/name', operator: 'In', values: ['mealie'] }
                      )
                    ),
    cronjob_restore: $._custom.cronjob_restore.new('mealie', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'mealie'),
    ingress_route: $._custom.ingress_route.new('mealie', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`mealie.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'mealie', port: 9000 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
    service: s.new('mealie',
                   { 'app.kubernetes.io/name': 'mealie' },
                   [
                     v1.servicePort.withPort(9000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'mealie' }),
    secret: v1.secret.new('mealie-secrets', {
              SMTP_PASSWORD: std.base64(std.extVar('secrets').smtp.password),
              OIDC_CLIENT_SECRET: std.base64(std.extVar('secrets').mealie.oidc.client_secret),
            })
            + v1.secret.metadata.withNamespace('self-hosted'),
    deployment: d.new('mealie',
                      if $.mealie.restore then 0 else 1,
                      [
                        c.new('mealie', $._version.mealie.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(9000, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          BASE_URL: std.format('https://mealie.%s', std.extVar('secrets').domain),
                          ALLOW_SIGNUP: 'false',
                          ALLOW_PASSWORD_LOGIN: 'false',
                          OIDC_AUTH_ENABLED: 'true',
                          OIDC_SIGNUP_ENABLED: 'true',
                          OIDC_CONFIGURATION_URL: std.format('https://auth.%s/.well-known/openid-configuration', std.extVar('secrets').domain),
                          OIDC_CLIENT_ID: 'mealie',
                          OIDC_AUTO_REDIRECT: 'false',
                          OIDC_PROVIDER_NAME: 'Authelia',
                          OIDC_USER_GROUP: 'mealie',
                          OIDC_ADMIN_GROUP: 'admin',
                          SMTP_AUTH_STRATEGY: 'TLS',
                          SMTP_HOST: std.extVar('secrets').smtp.server,
                          SMTP_FROM_EMAIL: std.format('mealie@%s', std.extVar('secrets').domain),
                          SMTP_USER: std.extVar('secrets').smtp.username,
                        })
                        + c.withEnvFrom(v1.envFromSource.secretRef.withName('mealie-secrets'))
                        + c.resources.withRequests({ memory: '300M', cpu: '100m' })
                        + c.resources.withLimits({ memory: '700M', cpu: '300m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.withRunAsUser(911)
                        + c.securityContext.withRunAsGroup(911)
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(15)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/api/app/about')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'mealie' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.pvcVolumeMount('mealie', '/app/data', false, {})
                + d.emptyVolumeMount('tmp', '/tmp', volumeMixin=v1.volume.emptyDir.withSizeLimit('100M'))
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.securityContext.withFsGroup(911)
                + d.metadata.withNamespace('self-hosted'),
  },
}
