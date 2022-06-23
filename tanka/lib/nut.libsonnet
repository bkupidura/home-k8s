{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  nut: {
    cron_job_ups_quick_check: $._custom.cronjob.new('quick-ups-battery-check', 'home-infra', '0 20 25 * *', [
      $.k.core.v1.container.new('battery-check', $._version.nut.image)
      + $.k.core.v1.container.withImagePullPolicy('IfNotPresent')
      + $.k.core.v1.container.withCommand([
        '/bin/sh',
        '-ec',
        std.format("/usr/local/ups/bin/upscmd -u admin -p '%s' apc@network-ups-tools.home-infra test.battery.start.quick", std.extVar('secrets').nut.admin),
      ]),
    ]),
    cron_job_ups_deep_check: $._custom.cronjob.new('deep-ups-battery-check', 'home-infra', '0 18 16 */6 *', [
      $.k.core.v1.container.new('battery-check', $._version.nut.image)
      + $.k.core.v1.container.withImagePullPolicy('IfNotPresent')
      + $.k.core.v1.container.withCommand([
        '/bin/sh',
        '-ec',
        std.format("/usr/local/ups/bin/upscmd -u admin -p '%s' apc@network-ups-tools.home-infra test.battery.start.deep", std.extVar('secrets').nut.admin),
      ]),
    ]),
    config: v1.configMap.new('network-ups-tools-config', {
              'nut.conf': |||
                MODE=netserver
              |||,
              'ups.conf': |||
                maxretry = 3
                [apc]
                  driver = usbhid-ups
                  port = auto
                  ignorelb
                  override.battery.charge.low = 3
                  override.battery.runtime.low = 5
              |||,
              'upsd.conf': |||
                LISTEN 0.0.0.0 3493
              |||,
              'upsd.users': |||
                              [admin]
                            |||
                            +
                            std.format('password = %s\n', std.extVar('secrets').nut.admin)
                            +
                            |||
                              actions = SET FSD
                              instcmds = ALL
                              upsmon master
                              [hass]
                            |||
                            +
                            std.format('password = %s\n', std.extVar('secrets').nut.hass),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    service: s.new('network-ups-tools', { 'app.kubernetes.io/name': 'network-ups-tools' }, [v1.servicePort.withPort(3493) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('nut')])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'network-ups-tools' }),
    deployment: d.new('network-ups-tools',
                      1,
                      [
                        c.new('network-ups-tools', $._version.nut.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(3493, 'nut'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '8Mi' })
                        + c.resources.withLimits({ memory: '16Mi' })
                        + c.securityContext.withPrivileged(true)
                        + c.readinessProbe.tcpSocket.withPort('nut')
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('nut')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1)
                        + c.lifecycle.postStart.exec.withCommand([
                          '/bin/sh',
                          '-ec',
                          std.join('\n', ['sleep 30', std.format('/usr/local/ups/bin/upscmd -u admin -p "%s" apc@127.0.0.1 beeper.disable', std.extVar('secrets').nut.admin)]),
                        ]),
                      ],
                      { 'app.kubernetes.io/name': 'network-ups-tools' })
                + d.configVolumeMount('network-ups-tools-config', '/etc/nut', {})
                + d.hostVolumeMount('dev-usb-hiddev0', '/dev/usb/hiddev0', '/dev/usb/hiddev0', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ ups_controller: 'true' })
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(10),
  },
}
