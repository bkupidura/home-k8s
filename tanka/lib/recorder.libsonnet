{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'recorder',
        rules: [
          {
            alert: 'RecorderWorkersHanging',
            expr: 'working_pool_task_in_progress > 0',
            'for': '30m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder worker {{ $labels.pool }} is running for more than 30m',
            },
          },
          {
            alert: 'RecorderWorkpoolBacklogHigh',
            expr: 'working_pool_work_backlog > 0',
            'for': '10m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder backlog is rising for {{ $labels.pool }}',
            },
          },
          {
            alert: 'RecorderErrors',
            expr: 'delta(working_pool_errors_total[5m]) > 0',
            'for': '1m',
            labels: { service: 'recorder', severity: 'warning' },
            annotations: {
              summary: 'Recorder errors observed for {{ $labels.pool }} in last 5m',
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
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '20Gi' }),
    ingress_route: $._custom.ingress_route.new('recorder', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`recorder.%s`) && (Path(`/`) || PathPrefix(`/recordings`))', std.extVar('secrets').domain),
        services: [{ name: 'recorder', port: 8080 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
      {
        kind: 'Rule',
        match: std.format('Host(`recorder.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'recorder', port: 8080 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
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
                ssh: { user: std.extVar('secrets').recorder.user, key: '/secret/id_rsa', server: std.extVar('secrets').recorder.server },
                upload: { workers: 4, timeout: 60, max_errors: 30 },
                record: { workers: 4, input_args: { rtsp_transport: 'tcp' }, output_args: { 'c:a': 'aac', 'c:v': 'copy' } },
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
                        + c.resources.withLimits({ memory: '512Mi' })
                        + c.securityContext.withPrivileged(true)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-dri-renderd128', '/dev/dri/renderD128', false),
                        ])
                        + c.readinessProbe.httpGet.withPath('/ready')
                        + c.readinessProbe.httpGet.withPort(8080)
                        + c.readinessProbe.withInitialDelaySeconds(5)
                        + c.readinessProbe.withPeriodSeconds(5)
                        + c.readinessProbe.withTimeoutSeconds(1)
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
                + d.metadata.withNamespace('smart-home')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                }),
  },
}
