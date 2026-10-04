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
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'bazarr', 'io.kubernetes.pod.namespace': 'arr' } }], toPorts: [{ ports: [{ port: '6767', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  falco+: {
    exception+:: {
      bazarr: {
        // bazarr run `ip link`
        'incubating-bazarr-entrypoint-setuid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_non_sudo_setuid_conditions',
            condition: std.format('or (container.image.repository=registry.%s/bazarr and evt.arg.uid=abc and proc.name=ip and proc.cmdline="ip link")', std.extVar('secrets').domain),
            override: {
              condition: 'append',
            },
          },
        ]),
      },
    },
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('bazarr.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:media',
          policy: 'one_factor',
        },
      },
    ],
  },
  bazarr: {
    restore:: $._config.restore,
    pvc: p.new('bazarr-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('bazarr', 'arr', '45 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'bazarr-config'),
    cronjob_restore: $._custom.cronjob_restore.new('bazarr', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'bazarr-config'),
    network_policy: $._custom.cilium_network_policy.new(
      'bazarr',
      'arr',
      { matchLabels: { 'app.kubernetes.io/name': 'bazarr' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '6767', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'sonarr' } },
          ],
          toPorts: [
            { ports: [{ port: '8989', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'radarr' } },
          ],
          toPorts: [
            { ports: [{ port: '7878', protocol: 'TCP' }] },
          ],
        },
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
      ],
    ),
    ingress_route: $._custom.ingress_route.new('bazarr', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`bazarr.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'bazarr', port: 6767 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    service: s.new('bazarr',
                   { 'app.kubernetes.io/name': 'bazarr' },
                   [
                     v1.servicePort.withPort(6767) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('arr')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'bazarr' }),
    deployment: d.new('bazarr',
                      if $.bazarr.restore then 0 else 1,
                      [
                        c.new('bazarr', $._version.bazarr.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(6767, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.resources.withRequests({ cpu: '150m', memory: '400Mi' })
                        + c.resources.withLimits({ cpu: '300m', memory: '800Mi' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withAdd(['CHOWN', 'SETGID', 'SETUID'])
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.httpGet.withPath('/ping')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(60)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/ping')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(120)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'bazarr' })
                + d.pvcVolumeMount('bazarr-config', '/config', false, {})
                + d.pvcVolumeMount('media', '/downloads', false, {})
                + d.emptyVolumeMount('run', '/run', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.emptyVolumeMount('tmp', '/tmp', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr'),
  },
}
