{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local st = $.k.storage.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  cilium+: {
    policy+: {
      traefik+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'jellyfin', 'io.kubernetes.pod.namespace': 'arr' } }], toPorts: [{ ports: [{ port: '8096', protocol: 'TCP' }] }] },
        ],
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'jellyfin', 'io.kubernetes.pod.namespace': 'arr' } }], toPorts: [{ ports: [{ port: '8443', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  jellyfin: {
    update:: $._config.update,
    restore:: $._config.restore,
    pvc: p.new('jellyfin-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '6Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('jellyfin', 'arr', '40 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'jellyfin-config'),
    cronjob_restore: $._custom.cronjob_restore.new('jellyfin', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'jellyfin-config'),
    network_policy: $._custom.cilium_network_policy.new(
      'jellyfin',
      'arr',
      { matchLabels: { 'app.kubernetes.io/name': 'jellyfin' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8096', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          toPorts: [
            { ports: [{ port: '53', protocol: 'ANY' }], rules: { dns: [{ matchPattern: '*' }] } },
          ],
        },
        {
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
            { cidr: std.format('%s/32', $._config.vip.ingress) },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    ingress_route: $._custom.ingress_route.new('jellyfin', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`jellyfin.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'jellyfin', port: 8096 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
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
                          v1.volumeMount.new('jellyfin-cache', '/cache', false),
                        ])
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8096, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          JELLYFIN_FFmpeg__probesize: '200M',
                        })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withDrop('all')
                        + (
                          if $.jellyfin.update == false then
                            c.resources.withRequests({ memory: '500Mi', cpu: '400m' })
                            + c.resources.withLimits({ memory: '1000Mi', cpu: '800m', 'devic.es/video-dri': 1 })
                            + c.readinessProbe.httpGet.withPath('/health')
                            + c.readinessProbe.httpGet.withPort('http')
                            + c.readinessProbe.withInitialDelaySeconds(10)
                            + c.readinessProbe.withPeriodSeconds(15)
                            + c.readinessProbe.withTimeoutSeconds(3)
                            + c.livenessProbe.httpGet.withPath('/health')
                            + c.livenessProbe.httpGet.withPort('http')
                            + c.livenessProbe.withInitialDelaySeconds(30)
                            + c.livenessProbe.withPeriodSeconds(15)
                            + c.livenessProbe.withTimeoutSeconds(5)
                          else
                            c.resources.withLimits({ 'devic.es/video-dri': 1 })
                        ),
                      ],
                      { 'app.kubernetes.io/name': 'jellyfin' })
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromEmptyDir('jellyfin-cache', emptyDir={ sizeLimit: '15Gi' }),
                ])
                + d.pvcVolumeMount('jellyfin-config', '/config', false, {})
                + d.pvcVolumeMount('media', '/media', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr')
                + d.spec.template.spec.withNodeSelector({ video_processing: 'true' }),
  },
}
