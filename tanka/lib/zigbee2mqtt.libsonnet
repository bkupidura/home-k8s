{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  zigbee2mqtt: {
    pvc: p.new('zigbee2mqtt')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route: $._custom.ingress_route.new('zigbee2mqtt', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`z2m.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'zigbee2mqtt', port: 8080, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('zigbee2mqtt', 'smart-home', '50 04 * * *', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default)]
    )], 'zigbee2mqtt'),
    cronjob_restore: $._custom.cronjob_restore.new('zigbee2mqtt', 'smart-home', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host zigbee2mqtt --target .', std.extVar('secrets').restic.repo.default)]
    )], 'zigbee2mqtt'),
    cronjob_zigbee_firmware_upgrade: $._custom.cronjob.new('zigbee-firmware-upgrade', 'smart-home', '0 0 * * *', [
                                       c.new('upgrade', $._version.zigbee2mqtt.deconz)
                                       + c.withImagePullPolicy('IfNotPresent')
                                       + c.withCommand([
                                         '/bin/sh',
                                         '-ec',
                                         std.join('\n', [
                                           std.format('curl "https://deconz.dresden-elektronik.de/deconz-firmware/%s" -o %s', [$._version.zigbee2mqtt.firmware, $._version.zigbee2mqtt.firmware]),
                                           std.format('curl "https://deconz.dresden-elektronik.de/deconz-firmware/%s.md5" -o %s.md5', [$._version.zigbee2mqtt.firmware, $._version.zigbee2mqtt.firmware]),
                                           std.format('md5sum -c %s.md5 || exit', $._version.zigbee2mqtt.firmware),
                                           std.format('/usr/bin/GCFFlasher_internal -f %s -d /dev/ttyACM0', $._version.zigbee2mqtt.firmware),
                                         ]),
                                       ])
                                       + c.withVolumeMounts(v1.volumeMount.new('adapter', '/dev/ttyACM0', false))
                                       + c.securityContext.withPrivileged(true),
                                     ])
                                     + $.k.batch.v1.cronJob.spec.withSuspend(true)
                                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes(v1.volume.fromHostPath('adapter', '/dev/ttyACM0'))
                                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                                       v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                                       + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['zigbee2mqtt'] }
                                       )
                                     )
                                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms(
                                       { matchExpressions: [{ key: 'zigbee_controller', operator: 'In', values: ['true'] }] },
                                     ),
    helm: $._custom.helm.new('zigbee2mqtt', 'https://k8s-at-home.com/charts/', $._version.zigbee2mqtt.chart, 'smart-home', {
      controller: {
        replicas: if $._config.restore then 0 else 1,
      },
      resources: {
        requests: { memory: '128Mi', cpu: '50m' },
        limits: { memory: '128Mi', cpu: '50m' },
      },
      env: { TZ: $._config.tz },
      image: { repository: $._version.zigbee2mqtt.repo, tag: $._version.zigbee2mqtt.tag },
      securityContext: { privileged: true },
      persistence: {
        data: { enabled: true, existingClaim: 'zigbee2mqtt' },
        usb: { enabled: true, type: 'hostPath', hostPath: '/dev/ttyACM0' },
      },
      ingress: { main: { enabled: false } },
      affinity: {
        nodeAffinity: {
          requiredDuringSchedulingIgnoredDuringExecution: {
            nodeSelectorTerms: [
              { matchExpressions: [{ key: 'zigbee_controller', operator: 'In', values: ['true'] }] },
            ],
          },
        },
      },
      config: {},
    }),
  },
}
