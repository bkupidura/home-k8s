{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  unifi: {
    restore:: $._config.restore,
    pvc: p.new('unifi')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '5Gi' }),
    ingress_route_https: $._custom.ingress_route.new('unifi', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`unifi.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'unifi', port: 443, namespace: 'home-infra', scheme: 'https' }],
        middlewares: [{ name: 'lanmgmt-whitelist', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    ingress_route_http: $._custom.ingress_route.new('unifi-http', 'home-infra', ['web'], [
      {
        kind: 'Rule',
        match: std.format('Host(`unifi.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'unifi', port: 80, namespace: 'home-infra', scheme: 'http' }],
        middlewares: [{ name: 'lanmgmt-whitelist', namespace: 'traefik-system' }],
      },
    ], null),
    cronjob_backup: $._custom.cronjob_backup.new('unifi', 'home-infra', '00 04 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'unifi'),
    cronjob_restore: $._custom.cronjob_restore.new('unifi', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host unifi --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'unifi'),
    service: s.new('unifi', { 'app.kubernetes.io/name': 'unifi' }, [
               v1.servicePort.withPort(80) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
               v1.servicePort.withPort(443) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('https'),
             ])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'unifi' }),
    deployment: d.new('unifi',
                      if $.unifi.restore then 0 else 1,
                      [
                        c.new('unifi', $._version.unifi.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(80, 'http'),
                          v1.containerPort.newNamed(443, 'https'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          JVM_MAX_HEAP_SIZE: '384M',
                          JVM_MAX_THREAD_STACK_SIZE: '1M',
                          RUNAS_UID0: 'false',
                          UNIFI_GID: '999',
                          UNIFI_UID: '999',
                          UNIFI_STDOUT: 'true',
                        })
                        + c.resources.withRequests({ memory: '512Mi' })
                        + c.resources.withLimits({ memory: '1Gi' })
                        + c.readinessProbe.tcpSocket.withPort('https')
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('https')
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1),
                      ],
                      { 'app.kubernetes.io/name': 'unifi' })
                + d.pvcVolumeMount('unifi', '/unifi', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(30),
  },
}
