{
  kubefledged: {
    namespace: $.k.core.v1.namespace.new('kube-fledged'),
    helm: $._custom.helm.new('kube-fledged',
                             'https://senthilrch.github.io/kubefledged-charts/',
                             $._version.kubefledged.chart,
                             'kube-fledged',
                             {
                               args: { controllerImageCacheRefreshFrequency: '60m' },
                               resources: {
                                 requests: { memory: '16Mi' },
                                 limits: { memory: '32Mi' },
                               },
                             }),
    imageCache: {
      apiVersion: 'kubefledged.io/v1alpha2',
      kind: 'ImageCache',
      metadata: {
        name: 'imagecache',
        namespace: 'kube-fledged',
        labels: {
          app: 'kubefledged',
          component: 'imagecache',
        },
      },
      spec: {
        cacheSpec: [
          {
            images: [
              std.format('%s:%s', [$._version.metallb.controller.repo, $._version.metallb.controller.tag]),
              std.format('%s:%s', [$._version.metallb.speaker.repo, $._version.metallb.speaker.tag]),
              std.format('%s:%s', [$._version.traefik.repo, $._version.traefik.tag]),
              $._version.mariadb.image,
              $._version.mariadb.metrics,
              $._version.coredns.image,
              $._version.blocky.image,
              $._version.authelia.image,
              $._version.zigbee2mqtt.image,
              $._version.home_assistant.image,
              $._version.node_red.image,
              $._version.recorder.image,
              $._version.frigate.image,
              $._version.sms_gammu.image,
              $._version.unifi.image,
              $._version.ubuntu.image,
            ],
          },
        ],
      },
    },
  },
}
