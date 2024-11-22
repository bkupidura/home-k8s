{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local st = $.k.storage.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'bazarr',
        rules: [
          {
            alert: 'K8sHighMemoryPodUsage',
            expr: 'max by (pod, namespace) (container_memory_working_set_bytes{container="bazarr"}) / 1024 / 1024 > 500',
            'for': '30m',
            labels: { service: 'k8s', severity: 'warning' },
            annotations: {
              summary: 'POD {{ $labels.pod }} is using {{ $value | printf "%.0f" }} megabytes of memory',
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
    cronjob_backup: $._custom.cronjob_backup.new('bazarr', 'arr', '20 06 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'bazarr-config'),
    cronjob_restore: $._custom.cronjob_restore.new('bazarr', 'arr', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'bazarr-config'),
    ingress_route: $._custom.ingress_route.new('bazarr', 'arr', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`bazarr.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'bazarr', port: 6767 }],
        middlewares: [{ name: 'x-forwarded-proto-https', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }, { name: 'lanhypervisor-whitelist', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
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
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('arr'),
  },
}
