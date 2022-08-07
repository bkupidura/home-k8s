{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  loki: {
    pvc: p.new('loki')
         + p.metadata.withNamespace('monitoring')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_without_snapshot.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '20Gi' }),
    helm: $._custom.helm.new('loki-stack', 'https://grafana.github.io/helm-charts', $._version.loki.chart, 'monitoring', {
      loki: {
        enabled: true,
        persistence: { enabled: true, existingClaim: 'loki' },
        resources: {
          requests: { memory: '128Mi' },
          limits: { memory: '156Mi' },
        },
      },
      promtail: {
        enabled: true,
        resources: {
          requests: { memory: '64Mi' },
          limits: { memory: '128Mi' },
        },
      },
      'fluent-bit': { enabled: false },
      grafana: { enabled: false },
      prometheus: { enabled: false },
      filebat: { enabled: false },
      logstash: { enabled: false },
    }),
  },
}
