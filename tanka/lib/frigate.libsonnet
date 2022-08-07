{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  frigate: {
    camera_snippet:: {
      [camera_name]: {
        detect: { fps: std.extVar('secrets').frigate.camera[camera_name].fps, height: std.extVar('secrets').frigate.camera[camera_name].height, width: std.extVar('secrets').frigate.camera[camera_name].width },
        ffmpeg: {
          inputs: [
            { path: std.extVar('secrets').frigate.camera[camera_name].path, roles: ['detect', 'rtmp'] },
          ],
        },
      }
      for camera_name in std.objectFields(std.extVar('secrets').frigate.camera)
    },
    pvc: p.new('frigate')
         + p.metadata.withNamespace('smart-home')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName('longhorn-standard')
         + p.spec.resources.withRequests({ storage: '1Gi' }),
    ingress_route: $._custom.ingress_route.new('frigate', 'smart-home', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`frigate.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'frigate', port: 5000 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
    config: v1.configMap.new('frigate-config', {
              'config.yml': std.manifestYamlDoc({
                mqtt: {
                  host: 'mqtt.home-infra',
                  port: 1883,
                  topic_prefix: 'frigate',
                  client_id: 'frigate',
                  user: 'frigate',
                  password: std.extVar('secrets').broker_ha.user.frigate,
                  stats_interval: 60,
                },
                ffmpeg: {
                  hwaccel_args: [
                    '-hwaccel',
                    'vaapi',
                    '-hwaccel_device',
                    '/dev/dri/renderD128',
                    '-hwaccel_output_format',
                    'yuv420p',
                  ],
                },
                cameras: $.frigate.camera_snippet,
                objects: {
                  track: ['person', 'cat'],
                  filters: {
                    person: { min_score: 0.7, threshold: 0.75 },
                    cat: { min_score: 0.6, threshold: 0.7 },
                  },
                },
                detect: { max_disappeared: 60 },
                rtmp: { enabled: false },
                record: { enabled: false },
                detectors: { cpu1: { type: 'cpu' } },
                snapshots: {
                  enabled: true,
                  timestamp: true,
                  bounding_box: true,
                  crop: true,
                  retain: { default: 1, objects: { person: 2 } },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('smart-home'),
    service: s.new('frigate', { 'app.kubernetes.io/name': 'frigate' }, [v1.servicePort.withPort(5000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('smart-home')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'frigate' }),
    deployment: d.new('frigate',
                      1,
                      [
                        c.new('frigate', $._version.frigate.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(5000, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '256Mi', cpu: '500m' })
                        + c.resources.withLimits({ memory: '512Mi', cpu: 1 })
                        + c.securityContext.withPrivileged(true)
                        + c.withVolumeMounts([
                          v1.volumeMount.new('dev-dri-renderd128', '/dev/dri/renderD128', false),
                        ])
                        + c.readinessProbe.tcpSocket.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(30)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(1)
                        + c.livenessProbe.tcpSocket.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(1),
                      ],
                      { 'app.kubernetes.io/name': 'frigate' })
                + d.spec.template.spec.withVolumes(v1.volume.fromHostPath('dev-dri-renderd128', '/dev/dri/renderD128') + v1.volume.hostPath.withType('CharDevice'))
                + d.configVolumeMount('frigate-config', '/config/config.yml', $.k.core.v1.volumeMount.withSubPath('config.yml'))
                + d.pvcVolumeMount('frigate', '/media', false, {})
                + d.emptyVolumeMount('cache', '/dev/shm', {}, v1.volume.emptyDir.withSizeLimit('500Mi'))
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withNodeSelector({ video_processing: 'true' })
                + d.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                  v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['recorder'] }
                  )
                )
                + d.metadata.withNamespace('smart-home'),
  },
}
