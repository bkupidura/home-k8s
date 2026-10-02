{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  cilium+: {
    policy+: {
      traefik+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'esphome', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '6052', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('esphome.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:smart-home-infra',
          policy: 'one_factor',
        },
      },
    ],
  },
  esphome: {
    network_policy: $._custom.cilium_network_policy.new(
      'esphome',
      'smart-home',
      { matchLabels: { 'app.kubernetes.io/name': 'esphome' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '6052', protocol: 'TCP' }] },
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
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }, { port: '80', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDR: [$._config.network.iot],
          toPorts: [
            { ports: [{ port: '3232', protocol: 'TCP' }, { port: '6053', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDR: ['224.0.0.251/32'],
          toPorts: [
            { ports: [{ port: '5353', protocol: 'UDP' }] },
          ],
        },
        {
          toCIDR: [
            $._config.network.iot,
          ],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'EchoRequest' }] },
          ],
        },
      ],
    ),
    pvc: p.new('esphome')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '10Gi' }),
    service: s.new(
               'esphome',
               { 'app.kubernetes.io/name': 'esphome' },
               [v1.servicePort.withPort(6052) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'esphome' }),
    ingress_route: $._custom.ingress_route.new('esphome', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`esphome.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'esphome', port: 6052, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('esphome', 'smart-home', '45 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
                      '\n',
                      ['cd /data', 'restic --verbose backup .']
                    )], 'esphome')
                    + { spec+: { jobTemplate+: { spec+: { template+: { spec+: { affinity: {} } } } } } },
    cronjob_restore: $._custom.cronjob_restore.new('esphome', 'smart-home', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'esphome'),
    deployment: d.new('esphome',
                      0,
                      [
                        c.new('esphome', $._version.esphome.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(6052, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.capabilities.withDrop('all')
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'esphome' })
                + d.pvcVolumeMount('esphome', '/config', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
