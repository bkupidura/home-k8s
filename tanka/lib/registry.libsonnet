{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  registry: {
    restore:: $._config.restore,
    pvc: p.new('registry')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '3Gi' }),
    service: s.new(
               'registry',
               { 'app.kubernetes.io/name': 'registry' },
               [v1.servicePort.withPort(5000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'registry' }),
    ingress_route: $._custom.ingress_route.new('registry', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`registry.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'registry', port: 5000, namespace: 'home-infra' }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('registry', 'home-infra', '15 05 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'registry'),
    cronjob_restore: $._custom.cronjob_restore.new('registry', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host registry --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'registry'),
    deployment: d.new('registry',
                      if $.registry.restore then 0 else 1,
                      [
                        c.new('registry', $._version.registry.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withEnvMap({
                          REGISTRY_STORAGE_DELETE_ENABLED: 'true',
                        })
                        + c.withPorts(v1.containerPort.newNamed(5000, 'http'))
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'registry' })
                + d.pvcVolumeMount('registry', '/var/lib/registry', false, {})
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
