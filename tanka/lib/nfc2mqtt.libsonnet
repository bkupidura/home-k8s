{
  local v1 = $.k.core.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  nfc2mqtt: {
    secret: v1.secret.new('nfc2mqtt-secrets', {
              'config.yaml': std.base64(std.manifestYamlDoc({
                nfc: {
                  reader: 'usb',
                  authenticate_password: std.extVar('secrets').nfc2mqtt.authenticate_password,
                  encrypt_key: std.extVar('secrets').nfc2mqtt.encrypt_key,
                  id_length: 10,
                },
                mqtt: {
                  server: 'mqtt.home-infra',
                  port: 1883,
                  keepalive: 30,
                  username: 'nfc2mqtt',
                  password: std.extVar('secrets').broker_ha.mqtt.users.nfc2mqtt.password,
                  topic: 'nfc2mqtt',
                },
                logging: {
                  level: 'info',
                },
              })),
            })
            + v1.secret.metadata.withNamespace('smart-home'),
    deployment: d.new('nfc2mqtt',
                      1,
                      [
                        c.new('nfc2mqtt', $._version.nfc2mqtt.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withCommand(['nfc2mqtt'])
                        + c.withArgs(['-c', '/etc/nfc2mqtt/config.yaml'])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '32Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '64Mi', cpu: '60m', 'devic.es/nfc-reader': 1 })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withDrop('all')
                        + c.livenessProbe.exec.withCommand(['kill', '-0', '1'])
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(30)
                        + c.livenessProbe.withTimeoutSeconds(5)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('nfc2mqtt-secrets', '/etc/nfc2mqtt/config.yaml', true) + v1.volumeMount.withSubPath('config.yaml'),
                        ]),
                      ],
                      { 'app.kubernetes.io/name': 'nfc2mqtt' })
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromSecret('nfc2mqtt-secrets', 'nfc2mqtt-secrets'),
                ])
                + d.emptyVolumeMount('tmp', '/tmp', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ nfc_controller: 'true' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
