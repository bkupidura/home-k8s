{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'authelia',
        rules: [
          {
            alert: 'AutheliaAuthFailureFirst',
            expr: 'round(delta(authelia_authentication_first_factor{success="false"}[10m])) > 2',
            labels: { service: 'authelia', severity: 'info' },
            annotations: {
              summary: 'Auth failues for first auth factor on {{ $labels.pod }}',
            },
          },
          {
            alert: 'AutheliaAuthFailureSecond',
            expr: 'round(delta(authelia_authentication_second_factor{success="false"}[10m])) > 2',
            labels: { service: 'authelia', severity: 'info' },
            annotations: {
              summary: 'Auth failues for second auth factor on {{ $labels.pod }}',
            },
          },
        ],
      },
    ],
  },
  authelia: {
    oidc_clients:: [
      {
        audience: [],
        authorization_policy: 'two_factor',
        description: client_name,
        grant_types: ['refresh_token', 'authorization_code'],
        id: client_name,
        public: false,
        redirect_uris: std.extVar('secrets').authelia.oidc.client[client_name].redirect_uris,
        response_modes: ['form_post', 'query', 'fragment'],
        response_types: ['code'],
        scopes: ['openid', 'groups', 'email', 'profile'],
        userinfo_signing_algorithm: 'none',
        secret: std.extVar('secrets').authelia.oidc.client[client_name].secret,
      }
      for client_name in std.objectFields(std.extVar('secrets').authelia.oidc.client)
    ],
    pvc: p.new('authelia')
         + p.metadata.withNamespace('home-infra')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '124Mi' }),
    service: s.new('authelia', { 'app.kubernetes.io/name': 'authelia' }, [v1.servicePort.withPort(9091) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('authelia')])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'authelia' }),
    ingress_route: $._custom.ingress_route.new('authelia', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`auth.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'authelia', port: 9091 }],
      },
    ], true),
    cronjob_backup: $._custom.cronjob_backup.new('authelia', 'home-infra', '00 05 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'authelia'),
    cronjob_restore: $._custom.cronjob_restore.new('authelia', 'home-infra', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --host authelia --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'authelia'),
    config: v1.configMap.new('authelia-config', {
              'users.yml': std.manifestYamlDoc({
                users: std.extVar('secrets').authelia.users,
              }),
              'configuration.yml': std.manifestYamlDoc(std.mergePatch({
                identity_providers: {
                  oidc: {
                    access_token_lifespan: '1h',
                    authorize_code_lifespan: '1m',
                    enable_client_debug_messages: true,
                    id_token_lifespan: '1h',
                    refresh_token_lifespan: '90m',
                    clients: $.authelia.oidc_clients,
                  },
                },
                authentication_backend: {
                  password_reset: { disable: true },
                  file: {
                    path: '/config/users.yml',
                    password: {
                      algorithm: 'argon2id',
                      iterations: 1,
                      salt_length: 16,
                      parallelism: 8,
                      memory: 64,
                    },
                  },
                },
                session: {
                  domain: std.extVar('secrets').domain,
                  expiration: 3600,
                  remember_me_duration: 2592000,
                },
                notifier: {
                  disable_startup_check: true,
                  smtp: {
                    host: std.extVar('secrets').smtp.server,
                    username: std.extVar('secrets').smtp.username,
                    password: std.extVar('secrets').smtp.password,
                    sender: std.format('auth@%s', std.extVar('secrets').domain),
                    port: std.extVar('secrets').smtp.port,
                    subject: '[Authelia] {title}',
                  },
                },
                telemetry: {
                  metrics: { enabled: true },
                },
                storage: {
                  'local': {
                    path: '/data/db.sqlite',
                  },
                },
                access_control: {
                  default_policy: 'deny',
                  rules: [
                    {
                      domain: std.format('*.%s', std.extVar('secrets').domain),
                      subject: 'group:admin',
                      policy: 'two_factor',
                    },
                  ],
                },
                regulation: {
                  max_retries: 3,
                  find_time: 300,
                  ban_time: 900,
                },
                default_redirection_url: std.format('https://auth.%s', std.extVar('secrets').domain),
                webauthn: {
                  disable: false,
                },
                server: {
                  buffers: {
                    read: 16384,
                    write: 16384,
                  },
                },
              }, std.extVar('secrets').authelia.config)),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('authelia',
                      if $._config.restore then 0 else 1,
                      [
                        c.new('authelia', $._version.authelia.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(9091, 'http'),
                          v1.containerPort.newNamed(9959, 'metrics'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '128Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '128Mi', cpu: '50m' })
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'authelia' })
                + d.configVolumeMount('authelia-config', '/config', {})
                + d.pvcVolumeMount('authelia', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9959',
                }),
  },
}
