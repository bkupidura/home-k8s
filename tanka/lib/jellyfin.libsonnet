{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local st = $.k.storage.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  jellyfin: {
    restore:: $._config.restore,
    pvc: p.new('jellyfin-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '3Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('jellyfin', 'arr', '40 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'jellyfin-config'),
    cronjob_restore: $._custom.cronjob_restore.new('jellyfin', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'jellyfin-config'),
    ingress_route: $._custom.ingress_route.new('jellyfin', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`jellyfin.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'jellyfin', port: 8096 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    service: s.new('jellyfin',
                   { 'app.kubernetes.io/name': 'jellyfin' },
                   [
                     v1.servicePort.withPort(8096) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('arr')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'jellyfin' }),
    deployment: d.new('jellyfin',
                      if $.jellyfin.restore then 0 else 1,
                      [
                        c.new('jellyfin', $._version.jellyfin.image)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-dri-renderd128', '/dev/dri/renderD128', false),
                          v1.volumeMount.new('jellyfin-cache', '/cache', false),
                        ])
                        + c.securityContext.withPrivileged(true)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8096, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          JELLYFIN_FFmpeg__probesize: '200M',
                        })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.resources.withRequests({ memory: '400Mi', cpu: '400m' })
                        + c.resources.withLimits({ memory: '800Mi', cpu: '800m' })
                        + c.readinessProbe.httpGet.withPath('/health')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/health')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'jellyfin' })
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromHostPath('dev-dri-renderd128', '/dev/dri/renderD128') + v1.volume.hostPath.withType('CharDevice'),
                  v1.volume.fromEmptyDir('jellyfin-cache', emptyDir={ sizeLimit: '15Gi' }),
                ])
                + d.pvcVolumeMount('jellyfin-config', '/config', false, {})
                + d.pvcVolumeMount('media', '/media', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr')
                + d.spec.template.spec.withNodeSelector({ video_processing: 'true' }),
  },
}
