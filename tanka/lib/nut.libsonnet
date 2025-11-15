{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'nut',
        rules: [
          {
            alert: 'NUTLowBattery',
            expr: 'network_ups_tools_battery_charge < 20',
            labels: { service: 'nut', severity: 'warning' },
            annotations: {
              summary: 'Low UPS battery reported {{ $value }}% on {{ $labels.param_ups }}',
            },
          },
          {
            alert: 'NUTPowerFailure',
            expr: 'network_ups_tools_ups_status{flag="OB"} == 1',
            labels: { service: 'nut', severity: 'info' },
            annotations: {
              summary: 'No power, running on batteries ({{ $labels.param_ups }})',
            },
          },
          {
            alert: 'NUTBatteryFailure',
            expr: 'network_ups_tools_ups_status{flag=~"RB|HB"} == 1',
            labels: { service: 'nut', severity: 'critical' },
            annotations: {
              summary: 'Battery failure, replace UPS batteries in {{ $labels.param_ups }}',
            },
          },
          {
            alert: 'NUTAlarm',
            expr: 'network_ups_tools_ups_status{flag="ALARM"} == 1',
            labels: { service: 'nut', severity: 'critical' },
            annotations: {
              summary: 'UPS reporting alarm {{ $labels.param_ups }}',
            },
          },
          {
            alert: 'NUTOverload',
            expr: 'network_ups_tools_ups_status{flag="OVER"} == 1',
            labels: { service: 'nut', severity: 'warning' },
            annotations: {
              summary: 'UPS overload detected on {{ $labels.param_ups }}!',
            },
          },
        ],
      },
    ],
  },
  nut: {
    cron_job_ups_quick_check: $._custom.cronjob.new('quick-ups-battery-check', 'home-infra', '0 20 25 * *', [
      $.k.core.v1.container.new('battery-check', $._version.nut.image)
      + $.k.core.v1.container.withImagePullPolicy('IfNotPresent')
      + $.k.core.v1.container.withCommand([
        '/bin/sh',
        '-ec',
        std.format("/usr/bin/upscmd -u admin -p '%s' apc@network-ups-tools.home-infra test.battery.start.quick", std.extVar('secrets').nut.admin),
      ]),
    ]),
    cron_job_ups_deep_check: $._custom.cronjob.new('deep-ups-battery-check', 'home-infra', '0 18 16 */6 *', [
      $.k.core.v1.container.new('battery-check', $._version.nut.image)
      + $.k.core.v1.container.withImagePullPolicy('IfNotPresent')
      + $.k.core.v1.container.withCommand([
        '/bin/sh',
        '-ec',
        std.format("/usr/bin/upscmd -u admin -p '%s' apc@network-ups-tools.home-infra test.battery.start.deep", std.extVar('secrets').nut.admin),
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
                            |||,
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
                        + c.withCommand([
                          '/bin/sh',
                          '-ec',
                          std.join('\n', ['mkdir /var/run/nut', '/usr/sbin/upsdrvctl -u root start', '/usr/sbin/upsd -u nut -F']),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '8Mi' })
                        + c.resources.withLimits({ memory: '16Mi' })
                        + c.securityContext.withPrivileged(true)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-bus-usb-001-004', '/dev/bus/usb/001/004', false),
                        ])
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
                          std.join('\n', ['sleep 30', std.format('/usr/bin/upscmd -u admin -p "%s" apc@127.0.0.1 beeper.disable', std.extVar('secrets').nut.admin)]),
                        ]),
                        c.new('exporter', $._version.nut.metrics)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(9199, 'metrics'))
                        + c.withEnvMap({
                          NUT_EXPORTER_USERNAME: 'admin',
                          NUT_EXPORTER_PASSWORD: std.extVar('secrets').nut.admin,
                          NUT_EXPORTER_VARIABLES: 'battery.charge,battery.voltage,battery.voltage.nominal,input.voltage,input.voltage.nominal,ups.load,ups.status,battery.runtime',
                        })
                        + c.resources.withRequests({ memory: '8Mi' })
                        + c.resources.withLimits({ memory: '16Mi' })
                        + c.readinessProbe.httpGet.withPath('/metrics')
                        + c.readinessProbe.httpGet.withPort('metrics')
                        + c.readinessProbe.withInitialDelaySeconds(20)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/metrics')
                        + c.livenessProbe.httpGet.withPort('metrics')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'network-ups-tools' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.spec.template.spec.withVolumes(v1.volume.fromHostPath('dev-bus-usb-001-004', '/dev/bus/usb/001/004') + v1.volume.hostPath.withType('CharDevice'))
                + d.configVolumeMount('network-ups-tools-config', '/etc/nut', {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ ups_controller: 'true' })
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(10)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9199',
                  'prometheus.io/path': '/ups_metrics',
                  'prometheus.io/param_ups': 'apc',
                }),
  },
}
