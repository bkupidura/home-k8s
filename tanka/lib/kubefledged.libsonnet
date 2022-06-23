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
              $._version.blocky.image,
              $._version.authelia.image,
              std.format('%s:%s', [$._version.zigbee2mqtt.repo, $._version.zigbee2mqtt.tag]),
              std.format('%s:%s', [$._version.home_assistant.repo, $._version.home_assistant.tag]),
              std.format('%s:%s', [$._version.node_red.repo, $._version.node_red.tag]),
              $._version.recorder.image,
              $._version.sms_gammu.image,
              std.format('%s:%s', [$._version.unifi.repo, $._version.unifi.tag]),
              $._version.ubuntu.image,
            ],
          },
        ],
      },
    },
  },
}
