{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  cilium+: {
    policy+: {
      traefik+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'node-red', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '1880', protocol: 'TCP' }] }] },
        ],
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'node-red', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '8443', protocol: 'TCP' }] }] },
        ],
      },
      'broker-ha'+: {
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'node-red', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '1883', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  node_red: {
    restore:: $._config.restore,
    network_policy: $._custom.cilium_network_policy.new(
      'node-red',
      'smart-home',
      { matchLabels: { 'app.kubernetes.io/name': 'node-red' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '1880', protocol: 'TCP' }] },
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
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'home-assistant', 'io.kubernetes.pod.namespace': 'smart-home' } },
          ],
          toPorts: [
            { ports: [{ port: '8123', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'broker-ha', 'io.kubernetes.pod.namespace': 'home-infra' } },
          ],
          toPorts: [
            { ports: [{ port: '1883', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'sms-gammu' } },
          ],
          toPorts: [
            { ports: [{ port: '5000', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'recorder' } },
          ],
          toPorts: [
            { ports: [{ port: '8080', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'unifi', 'io.kubernetes.pod.namespace': 'home-infra' } },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
        {
          toFQDNs: [
            { matchName: 'api.bulksms.com' },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDRSet: [
            { cidr: std.format('%s/32', $._config.vip.ingress) },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    pvc: p.new('node-red')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '512Mi' }),
    ingress_route: $._custom.ingress_route.new('node-red', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`node-red.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'node-red', port: 1880, namespace: 'smart-home' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('node-red', 'smart-home', '55 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'node-red'),
    cronjob_restore: $._custom.cronjob_restore.new('node-red', 'smart-home', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'node-red'),
    service: s.new('node-red', { 'app.kubernetes.io/name': 'node-red' }, [v1.servicePort.withPort(1880) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'node-red' }),
    deployment: d.new('node-red',
                      if $.node_red.restore then 0 else 1,
                      [
                        c.new('node-red', $._version.node_red.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(1880, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          FLOWS: 'flows.json',
                        })
                        + c.resources.withRequests({ memory: '192Mi', cpu: '500m' })
                        + c.resources.withLimits({ memory: '192Mi', cpu: '500m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/dead-man-switch')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'node-red' })
                + d.pvcVolumeMount('node-red', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.securityContext.withFsGroup(1000)
                + d.spec.template.spec.withTerminationGracePeriodSeconds(30)
                + d.spec.template.spec.affinity.podAntiAffinity.withPreferredDuringSchedulingIgnoredDuringExecution(
                  v1.weightedPodAffinityTerm.withWeight(1)
                  + v1.weightedPodAffinityTerm.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.weightedPodAffinityTerm.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['zigbee2mqtt', 'home-assistant'] }
                  )
                ),
  },
}
