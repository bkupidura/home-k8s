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
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'home-assistant', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '8123', protocol: 'TCP' }] }] },
        ],
      },
      mariadb+: {
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'home-assistant', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '3306', protocol: 'TCP' }] }] },
        ],
      },
      'broker-ha'+: {
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'home-assistant', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '1883', protocol: 'TCP' }] }] },
        ],
      },
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'home-assistant', 'io.kubernetes.pod.namespace': 'smart-home' } }], toPorts: [{ ports: [{ port: '8123', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  monitoring+: {
    extra_scrape+:: {
      home_assistant: {
        bearer_token: std.extVar('secrets').home_assistant.bearer_token,
        job_name: 'home-assistant',
        metric_relabel_configs: [
          { action: 'labeldrop', regex: 'friendly_name' },
          { regex: '.*\\.(.*)', replacement: '${1}', source_labels: ['entity'], target_label: 'entity_name' },
        ],
        metrics_path: '/api/prometheus',
        scheme: 'http',
        scrape_interval: '10s',
        static_configs: [
          { targets: ['home-assistant.smart-home:8123'] },
        ],
      },
    },
  },
  home_assistant: {
    update:: $._config.update,
    restore:: $._config.restore,
    network_policy: $._custom.cilium_network_policy.new(
      'home-assistant',
      'smart-home',
      { matchLabels: { 'app.kubernetes.io/name': 'home-assistant' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8123', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'node-red', 'io.kubernetes.pod.namespace': 'smart-home' } },
          ],
          toPorts: [
            { ports: [{ port: '8123', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '8123', protocol: 'TCP' }] },
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
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'DestinationUnreachable' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'mariadb', 'io.kubernetes.pod.namespace': 'home-infra' } },
          ],
          toPorts: [
            { ports: [{ port: '3306', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'nextcloud', 'io.kubernetes.pod.namespace': 'self-hosted' } },
          ],
          toPorts: [
            { ports: [{ port: '80', protocol: 'TCP' }] },
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
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
          ],
          toPorts: [
            { ports: [{ port: '8883', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDR: ['255.255.255.255/32'],
          toPorts: [
            { ports: [{ port: '7000', protocol: 'UDP' }, { port: '1900', protocol: 'UDP' }] },
          ],
        },
        {
          toCIDR: ['239.255.255.250/32'],
          toPorts: [
            { ports: [{ port: '1900', protocol: 'UDP' }] },
          ],
        },
        {
          toCIDR: ['224.0.0.251/32'],
          toPorts: [
            { ports: [{ port: '5353', protocol: 'UDP' }] },
          ],
        },
        {
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
          ],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'EchoRequest' }] },
          ],
        },
        {
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    pvc: p.new('home-assistant')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '3Gi' }),
    ingress_route: $._custom.ingress_route.new('home-assistant', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`ha.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'home-assistant', port: 8123, namespace: 'smart-home' }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('home-assistant', 'smart-home', '50 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'home-assistant'),
    cronjob_restore: $._custom.cronjob_restore.new('home-assistant', 'smart-home', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'home-assistant'),
    service: s.new('home-assistant', { 'app.kubernetes.io/name': 'home-assistant' }, [v1.servicePort.withPort(8123) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'home-assistant' }),
    deployment: d.new('home-assistant',
                      if $.home_assistant.restore then 0 else 1,
                      [
                        c.new('home-assistant', $._version.home_assistant.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8123, 'http'),
                          v1.containerPort.newNamed(1400, 'sonos'),
                          v1.containerPort.newNamedUDP(5683, 'shelly-coap'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withDrop('all')
                        + (if $.home_assistant.update == false then
                             c.resources.withRequests({ memory: '800Mi', cpu: '300m' })
                             + c.resources.withLimits({ memory: '800Mi', cpu: '300m' })
                             + c.readinessProbe.tcpSocket.withPort('http')
                             + c.readinessProbe.withInitialDelaySeconds(30)
                             + c.readinessProbe.withPeriodSeconds(15)
                             + c.readinessProbe.withTimeoutSeconds(2)
                             + c.livenessProbe.httpGet.withPath('/healthz')
                             + c.livenessProbe.httpGet.withPort('http')
                             + c.livenessProbe.withInitialDelaySeconds(120)
                             + c.livenessProbe.withPeriodSeconds(15)
                             + c.livenessProbe.withTimeoutSeconds(5)
                           else {}),
                      ],
                      { 'app.kubernetes.io/name': 'home-assistant' })
                + d.pvcVolumeMount('home-assistant', '/config', false, {})
                + d.emptyVolumeMount('run', '/run', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.emptyVolumeMount('tmp', '/tmp', volumeMixin=v1.volume.emptyDir.withSizeLimit('10M'))
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withEnableServiceLinks(true)
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(30)
                + d.spec.template.metadata.withAnnotations({
                  'k8s.v1.cni.cncf.io/networks': '[{"name": "multus-dhcp-lan", "mac": "e8:d1:44:8d:65:b0", "namespace": "kube-system"}, {"name": "multus-dhcp-iot", "mac": "e8:d1:44:8d:65:b1", "namespace": "kube-system"}]',
                })
                + d.spec.template.spec.affinity.podAntiAffinity.withPreferredDuringSchedulingIgnoredDuringExecution(
                  v1.weightedPodAffinityTerm.withWeight(1)
                  + v1.weightedPodAffinityTerm.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.weightedPodAffinityTerm.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['zigbee2mqtt', 'node-red'] }
                  )
                ),
  },
}
