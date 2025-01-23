{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  authelia+: {
    access_control+:: [
      {
        order: 0,
        rule: {
          domain: std.format('node-red.%s', std.extVar('secrets').domain),
          networks: [$._config.kubernetes_internal_cidr],
          policy: 'bypass',
        },
      },
      {
        order: 1,
        rule: {
          domain: [
            std.format('node-red.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:smart-home-infra',
          policy: 'two_factor',
        },
      },
    ],
  },
  node_red: {
    restore:: $._config.restore,
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
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    cronjob_backup: $._custom.cronjob_backup.new('node-red', 'smart-home', '55 03 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'node-red'),
    cronjob_restore: $._custom.cronjob_restore.new('node-red', 'smart-home', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
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
