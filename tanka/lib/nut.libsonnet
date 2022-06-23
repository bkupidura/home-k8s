{
  nut: {
    cron_job_ups_quick_check: $._custom.cronjob.new('quick-ups-battery-check', 'home-infra', '0 20 25 * *', [
      $.k.core.v1.container.new('battery-check', $._version.nut.repo + ':' + $._version.nut.tag)
      + $.k.core.v1.container.withImagePullPolicy('IfNotPresent')
      + $.k.core.v1.container.withCommand([
        '/bin/sh',
        '-ec',
        std.format("/usr/local/ups/bin/upscmd -u admin -p '%s' apc@network-ups-tools.home-infra test.battery.start.quick", std.extVar('secrets').nut.admin),
      ]),
    ]),
    cron_job_ups_deep_check: $._custom.cronjob.new('deep-ups-battery-check', 'home-infra', '0 18 16 */6 *', [
      $.k.core.v1.container.new('battery-check', $._version.nut.repo + ':' + $._version.nut.tag)
      + $.k.core.v1.container.withImagePullPolicy('IfNotPresent')
      + $.k.core.v1.container.withCommand([
        '/bin/sh',
        '-ec',
        std.format("/usr/local/ups/bin/upscmd -u admin -p '%s' apc@network-ups-tools.home-infra test.battery.start.deep", std.extVar('secrets').nut.admin),
      ]),
    ]),
    helm: $._custom.helm.new('network-ups-tools',
                             'https://k8s-at-home.com/charts/',
                             $._version.nut.chart,
                             'home-infra',
                             {
                               resources: {
                                 requests: { memory: '8Mi' },
                                 limits: { memory: '16Mi' },
                               },
                               lifecycle: {
                                 postStart: {
                                   exec: {
                                     command: [
                                       '/bin/sh',
                                       '-ec',
                                       std.join('\n', ['sleep 30', "/usr/local/ups/bin/upscmd -u admin -p '" + std.extVar('secrets').nut.admin + "' apc@127.0.0.1 beeper.disable"]),
                                     ],
                                   },
                                 },
                               },
                               image: { repository: $._version.nut.repo, tag: $._version.nut.tag },
                               env: { TZ: $._config.tz },
                               service: {
                                 main: {
                                   ports: {
                                     http: { enabled: false },
                                     server: { enabled: true },
                                   },
                                 },
                               },
                               securityContext: { privileged: true },
                               persistence: {
                                 usb: {
                                   enabled: true,
                                   type: 'hostPath',
                                   hostPath: '/dev/usb/hiddev0',
                                 },
                               },
                               config: {
                                 mode: 'values',
                                 files: {
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
                                 },
                               },
                               affinity: {
                                 nodeAffinity: {
                                   requiredDuringSchedulingIgnoredDuringExecution: {
                                     nodeSelectorTerms: [
                                       {
                                         matchExpressions: [
                                           {
                                             key: 'ups_controller',
                                             operator: 'In',
                                             values: ['true'],
                                           },
                                         ],
                                       },
                                     ],
                                   },
                                 },
                               },
                             }),
  },
}
