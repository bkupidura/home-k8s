{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  frigate: {
    camera_snippet:: {
      [camera_name]: {
        detect: { fps: std.extVar('secrets').frigate.camera[camera_name].fps, height: std.extVar('secrets').frigate.camera[camera_name].height, width: std.extVar('secrets').frigate.camera[camera_name].width },
        ffmpeg: {
          inputs: [
            { path: std.extVar('secrets').frigate.camera[camera_name].path, roles: ['detect', 'rtmp'] },
          ],
        },
        record: { enabled: false },
        rtmp: { enabled: true },
        snapshots: {
          bounding_box: true,
          crop: true,
          retain: { default: 1, objects: { person: 2 } },
          timestamp: true,
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
    helm: $._custom.helm.new('frigate', 'https://k8s-at-home.com/charts/', $._version.frigate.chart, 'smart-home', {
      resources: {
        requests: { memory: '256Mi', cpu: '500m' },
        limits: { memory: '512Mi', cpu: '1000m' },
      },
      affinity: {
        podAntiAffinity: {
          requiredDuringSchedulingIgnoredDuringExecution: [
            {
              labelSelector: {
                matchExpressions: [
                  { key: 'app.kubernetes.io/name', operator: 'In', values: ['recorder'] },
                ],
              },
              topologyKey: 'kubernetes.io/hostname',
            },
          ],
        },
        nodeAffinity: {
          requiredDuringSchedulingIgnoredDuringExecution: {
            nodeSelectorTerms: [{ matchExpressions: [{ key: 'video_processing', operator: 'In', values: ['true'] }] }],
          },
        },
      },
      replicaCount: 1,
      strategyType: 'Recreate',
      env: { TZ: $._config.tz },
      image: { repository: $._version.frigate.repo, tag: $._version.frigate.tag },
      service: {
        main: {
          ports: {
            http: { port: 5000, enabled: true },
            rtmp: { enabled: true },
          },
        },
      },
      ingress: { main: { enabled: false } },
      securityContext: { privileged: true },
      persistence: {
        media: { enabled: true, existingClaim: 'frigate' },
        usb: { enabled: true, type: 'hostPath', hostPath: '/dev/dri/renderD128' },
        cache: { enabled: true, type: 'emptyDir', medium: 'Memory', sizeLimit: '500Mi', mountPath: '/dev/shm' },
      },
      configmap: {
        config: {
          enabled: true,
          data: {
            'config.yml': std.manifestYamlDoc({
              mqtt: {
                host: 'mqtt.smart-home',
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
                  person: { min_score: 0.7, threshold: 0.7 },
                  cat: { min_score: 0.6, threshold: 0.7 },
                },
              },
              detect: { max_disappeared: 60 },
              record: { enabled: false },
              detectors: { cpu1: { type: 'cpu' } },
            }),
          },
        },
      },
    }),
  },
}
