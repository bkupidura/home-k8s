{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  zigbee2mqtt: {
    restore:: $._config.restore,
    pvc: p.new('zigbee2mqtt')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '128Mi' }),
    ingress_route: $._custom.ingress_route.new('zigbee2mqtt', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`z2m.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'zigbee2mqtt', port: 8080, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('zigbee2mqtt', 'smart-home', '50 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'zigbee2mqtt'),
    cronjob_restore: $._custom.cronjob_restore.new('zigbee2mqtt', 'smart-home', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host zigbee2mqtt --target .', std.extVar('secrets').restic.repo.default.connection)]
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
                                       + c.withVolumeMounts(v1.volumeMount.new('dev-ttyacm0', '/dev/ttyACM0', false))
                                       + c.securityContext.withPrivileged(true),
                                     ])
                                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                       $.k.core.v1.volume.fromHostPath('dev-ttyacm0', '/dev/ttyACM0') + v1.volume.hostPath.withType('CharDevice'),
                                     ])
                                     + $.k.batch.v1.cronJob.spec.withSuspend(true)
                                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                                       v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                                       + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['zigbee2mqtt'] }
                                       )
                                     )
                                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms(
                                       { matchExpressions: [{ key: 'zigbee_controller', operator: 'In', values: ['true'] }] },
                                     ),
    service: s.new('zigbee2mqtt', { 'app.kubernetes.io/name': 'zigbee2mqtt' }, [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'zigbee2mqtt' }),
    deployment: d.new('zigbee2mqtt',
                      if $.zigbee2mqtt.restore then 0 else 1,
                      [
                        c.new('zigbee2mqtt', $._version.zigbee2mqtt.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          ZIGBEE2MQTT_DATA: '/app/data',
                        })
                        + c.resources.withRequests({ memory: '128Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '128Mi', cpu: '50m' })
                        + c.securityContext.withPrivileged(true)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-ttyacm0', '/dev/ttyACM0', false),
                        ])
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(120)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'zigbee2mqtt' })
                + d.spec.template.spec.withVolumes(v1.volume.fromHostPath('dev-ttyacm0', '/dev/ttyACM0') + v1.volume.hostPath.withType('CharDevice'))
                + d.pvcVolumeMount('zigbee2mqtt', '/app/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ zigbee_controller: 'true' })
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(30),
  },
}
