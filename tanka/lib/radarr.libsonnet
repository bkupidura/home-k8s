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
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'radarr', 'io.kubernetes.pod.namespace': 'arr' } }], toPorts: [{ ports: [{ port: '7878', protocol: 'TCP' }] }] },
        ],
      },
      nzbget+: {
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'radarr', 'io.kubernetes.pod.namespace': 'arr' } }], toPorts: [{ ports: [{ port: '6789', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  logging+: {
    rules+:: [
      {
        name: 'radarr',
        interval: '1m',
        rules: [
          {
            alert: 'RadarrApiRequestLimit',
            expr: '_time:5m kubernetes__container_name: "radarr" and i("api request limit reached for") | stats by (kubernetes__pod_name) count() as log_count| filter log_count :> 0',
            labels: { service: 'radarr', severity: 'info' },
            annotations: {
              summary: 'Radarr api request limit reached on {{ index $labels "kubernetes__pod_name" }}',
            },
          },
          {
            alert: 'RadarrDBError',
            expr: '_time:5m kubernetes__container_name: "radarr" and i("database disk image is malformed") | stats by (kubernetes__pod_name) count() as log_count| filter log_count :> 0',
            labels: { service: 'radarr', severity: 'warning' },
            annotations: {
              summary: 'Radarr database corrupted on {{ index $labels "kubernetes__pod_name" }}',
            },
          },
        ],
      },
    ],
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('radarr.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:media',
          policy: 'one_factor',
        },
      },
    ],
  },
  radarr: {
    restore:: $._config.restore,
    pvc: p.new('radarr-config')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '2Gi' }),
    cronjob_backup: $._custom.cronjob_backup.new('radarr', 'arr', '25 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose backup .']
    )], 'radarr-config'),
    cronjob_restore: $._custom.cronjob_restore.new('radarr', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', 'restic --verbose restore latest --target .']
    )], 'radarr-config'),
    network_policy: $._custom.cilium_network_policy.new(
      'radarr',
      'arr',
      { matchLabels: { 'app.kubernetes.io/name': 'radarr' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
            { matchLabels: { 'app.kubernetes.io/name': 'bazarr' } },
          ],
          toPorts: [
            { ports: [{ port: '7878', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'nzbget' } },
          ],
          toPorts: [
            { ports: [{ port: '6789', protocol: 'TCP' }] },
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
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    ingress_route: $._custom.ingress_route.new('radarr', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`radarr.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'radarr', port: 7878 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    service: s.new('radarr',
                   { 'app.kubernetes.io/name': 'radarr' },
                   [
                     v1.servicePort.withPort(7878) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('arr')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'radarr' }),
    deployment: d.new('radarr',
                      if $.radarr.restore then 0 else 1,
                      [
                        c.new('radarr', $._version.radarr.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(7878, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.resources.withRequests({ memory: '200Mi', cpu: '75m' })
                        + c.resources.withLimits({ memory: '500Mi', cpu: '150m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withAdd(['SETUID', 'SETGID', 'CHOWN', 'DAC_OVERRIDE'])
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.httpGet.withPath('/ping')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/ping')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(5),
                      ],
                      { 'app.kubernetes.io/name': 'radarr' })
                + d.pvcVolumeMount('radarr-config', '/config', false, {})
                + d.pvcVolumeMount('media', '/downloads', false, {})
                + d.emptyVolumeMount('run', '/run', volumeMixin=v1.volume.emptyDir.withSizeLimit('20M'))
                + d.emptyVolumeMount('tmp', '/tmp', volumeMixin=v1.volume.emptyDir.withSizeLimit('20M'))
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr'),
  },
}
