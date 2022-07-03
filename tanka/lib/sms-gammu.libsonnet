{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  sms_gammu: {
    secret: $.k.core.v1.secret.new('sms-gammu-secret', {
              'credentials.txt': std.base64(std.format('admin:%s', std.extVar('secrets').sms_gammu.password)),
            })
            + $.k.core.v1.secret.metadata.withNamespace('smart-home'),
    service: s.new('sms-gammu', { 'app.kubernetes.io/name': 'sms-gammu' }, [v1.servicePort.withPort(5000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('sms-gammu')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'sms-gammu' }),
    deployment: d.new('sms-gammu',
                      1,
                      [
                        c.new('sms-gammu', $._version.sms_gammu.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(5000, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '16Mi' })
                        + c.resources.withLimits({ memory: '32Mi' })
                        + c.securityContext.withPrivileged(true)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-ttyusb0', '/dev/mobile', false),
                        ])
                        + c.livenessProbe.httpGet.withPath('/signal')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'sms-gammu' })
                + d.spec.template.spec.withVolumes(v1.volume.fromHostPath('dev-ttyusb0', '/dev/ttyUSB0') + v1.volume.hostPath.withType('CharDevice'))
                + d.secretVolumeMount('sms-gammu-secret', '/sms-gw/credentials.txt', 256, $.k.core.v1.volumeMount.withSubPath('credentials.txt'))
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ modem_controller: 'true' })
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
