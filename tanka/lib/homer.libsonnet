{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('catalog.%s', std.extVar('secrets').domain),
          ],
          policy: 'one_factor',
        },
      },
    ],
  },
  homer: {
    service: s.new(
               'homer',
               { 'app.kubernetes.io/name': 'homer' },
               [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'homer' }),
    ingress_route: $._custom.ingress_route.new('catalog', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`catalog.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'homer', port: 8080, namespace: 'self-hosted' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    config: v1.configMap.new('homer-config', {
              'config.yml': std.manifestYamlDoc({
                title: 'Catalog',
                subtitle: 'Homer',
                logo: 'logo.png',
                header: true,
                footer: false,
                theme: 'default',
                colors: {
                  light: {
                    'highlight-primary': '#3367d6',
                    'highlight-secondary': '#4285f4',
                    'highlight-hover': '#5a95f5',
                    background: '#f5f5f5',
                    'card-background': '#ffffff',
                    text: '#363636',
                    'text-header': '#ffffff',
                    'text-title': '#303030',
                    'text-subtitle': '#424242',
                    'card-shadow': 'rgba(0, 0, 0, 0.1)',
                    link: '#3273dc',
                    'link-hover': '#363636',
                  },
                  dark: {
                    'highlight-primary': '#3367d6',
                    'highlight-secondary': '#4285f4',
                    'highlight-hover': '#5a95f5',
                    background: '#131313',
                    'card-background': '#2b2b2b',
                    text: '#eaeaea',
                    'text-header': '#ffffff',
                    'text-title': '#fafafa',
                    'text-subtitle': '#f5f5f5',
                    'card-shadow': 'rgba(0, 0, 0, 0.4)',
                    link: '#3273dc',
                    'link-hover': '#ffdd57',
                  },
                },
                links: [],
                services: [
                  {
                    name: 'Files',
                    icon: 'fas fa-cloud',
                    items: [
                      {
                        name: 'Nextcloud',
                        icon: 'fa-solid fa-download',
                        subtitle: 'File storage',
                        url: std.format('https://files.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                      {
                        name: 'Paperless',
                        icon: 'fa-solid fa-paperclip',
                        subtitle: 'Document storage',
                        url: std.format('https://paperless.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                      {
                        name: 'Immich',
                        icon: 'fa-solid fa-camera',
                        subtitle: 'Photo storage',
                        url: std.format('https://photos.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                    ],
                  },
                  {
                    name: 'Entertaiment',
                    icon: 'fas fa-puzzle-piece',
                    items: [
                      {
                        name: 'Radarr',
                        icon: 'fa-solid fa-film',
                        subtitle: 'Movie download',
                        url: std.format('https://radarr.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                      {
                        name: 'Sonarr',
                        icon: 'fa-solid fa-television',
                        subtitle: 'TV series download',
                        url: std.format('https://sonarr.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                      {
                        name: 'Jellyfin',
                        icon: 'fa-solid fa-ticket',
                        subtitle: 'Media player',
                        url: std.format('https://jellyfin.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                    ],
                  },
                  {
                    name: 'Tools',
                    icon: 'fas fa-wrench',
                    items: [
                      {
                        name: 'Vaultwarden',
                        icon: 'fa-solid fa-lock',
                        subtitle: 'Password manager',
                        url: std.format('https://vaultwarden.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                      {
                        name: 'FreshRSS',
                        icon: 'fa-solid fa-rss',
                        subtitle: 'RSS reader',
                        url: std.format('https://rss.%s', std.extVar('secrets').domain),
                        target: '_blank',
                      },
                    ],
                  },
                ],
              }),
            })
            + v1.configMap.metadata.withNamespace('self-hosted'),
    deployment: d.new('homer',
                      1,
                      [
                        c.new('homer', $._version.homer.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          INIT_ASSETS: '0',
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('homer-config', '/www/assets/config.yml', false) + v1.volumeMount.withSubPath('config.yml'),
                        ])
                        + c.resources.withRequests({ memory: '10Mi', cpu: '10m' })
                        + c.resources.withLimits({ memory: '20Mi', cpu: '20m' })
                        + c.readinessProbe.httpGet.withPath('/')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(15)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'homer' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.spec.template.spec.withVolumes(v1.volume.fromConfigMap('homer-config', 'homer-config'))
                + d.spec.strategy.withType('RollingUpdate')
                + d.metadata.withNamespace('self-hosted')
                + d.spec.template.spec.securityContext.withFsGroup(1000)
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
