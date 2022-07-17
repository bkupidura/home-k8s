{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  prometheus+: {
    rules+:: [
      {
        name: 'recorder',
        rules: [
          {
            alert: 'RecorderWorkersHanging',
            expr: 'recorder_workers > 0',
            'for': '30m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder worker {{ $labels.service }} is running for more than 30m',
            },
          },
          {
            alert: 'RecorderErrors',
            expr: 'delta(recorder_errors_total[5m]) > 0',
            'for': '1m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder errors observed for {{ $labels.service }} in last 5m',
            },
          },
        ],
      },
    ],
  },
  recorder: {
    pvc: p.new('recorder')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '30Gi' }),
    ingress_route: $._custom.ingress_route.new('recorder', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`recorder.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'recorder', port: 8080 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    cronjob_cleanup: $._custom.cronjob.new('recorder-cleanup', 'smart-home', '15 6,18 * * *', [
                       $.k.core.v1.container.new('cleanup', $._version.ubuntu.image)
                       + $.k.core.v1.container.withVolumeMounts([
                         $.k.core.v1.volumeMount.new('data', '/data', false),
                       ])
                       + $.k.core.v1.container.withCommand([
                         '/bin/sh',
                         '-ec',
                         std.join('\n', ['find /data -type f -mtime +7 -delete', 'find /data -mindepth 1 -type d -empty -delete']),
                       ]),
                     ])
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([$.k.core.v1.volume.fromPersistentVolumeClaim('data', 'recorder')])
                     + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                       $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                       + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                         { key: 'app.kubernetes.io/name', operator: 'In', values: ['recorder'] }
                       )
                     ),
    config: v1.configMap.new('recorder-config', {
              'config.yml': std.manifestYamlDoc({
                mqtt: {
                  topic: 'recorder',
                  server: 'mqtt.home-infra:1883',
                  user: 'recorder',
                  password: std.extVar('secrets').broker_ha.user.recorder,
                },
                ssh: { user: 'recorder', key: '/secret/id_rsa', server: std.extVar('secrets').recorder.server },
                upload: { workers: 4, timeout: 60, max_errors: 30 },
                record: { workers: 4, burst_overlap: 2, input_args: { rtsp_transport: 'tcp' } },
                convert: {
                  workers: 1,
                  input_args: { f: 'concat', vaapi_device: '/dev/dri/renderD128', hwaccel: 'vaapi', safe: 0 },
                  output_args: { 'c:a': 'copy', 'c:v': 'h264_vaapi', preset: 'veryfast', vf: 'format=nv12|vaapi,hwupload' },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('smart-home'),
    secret: $.k.core.v1.secret.new('recorder-secret', {
              id_rsa: std.base64(std.extVar('secrets').recorder.key),
            })
            + $.k.core.v1.secret.metadata.withNamespace('smart-home'),
    service: s.new('recorder', { 'app.kubernetes.io/name': 'recorder' }, [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('recorder')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'recorder' }),
    deployment: d.new('recorder',
                      1,
                      [
                        c.new('recorder', $._version.recorder.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '128Mi' })
                        + c.resources.withLimits({ memory: '256Mi' })
                        + c.securityContext.withPrivileged(true)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-dri-renderd128', '/dev/dri/renderD128', false),
                        ])
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'recorder' })
                + d.spec.template.spec.withVolumes(v1.volume.fromHostPath('dev-dri-renderd128', '/dev/dri/renderD128') + v1.volume.hostPath.withType('CharDevice'))
                + d.configVolumeMount('recorder-config', '/config/', {})
                + d.secretVolumeMount('recorder-secret', '/secret/', 256, {})
                + d.pvcVolumeMount('recorder', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ video_processing: 'true' })
                + d.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                  v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['frigate'] }
                  )
                )
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                }),
  },
}
