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
            alert: 'AutheliaAuthFailure',
            expr: 'round(delta(authelia_authn{success="false"}[10m])) > 2',
            labels: { service: 'authelia', severity: 'info' },
            annotations: {
              summary: 'Auth failues observed by {{ $labels.pod }}',
            },
          },
        ],
      },
    ],
  },
  authelia: {
    access_control:: [],
    access_control_rendered:: [
      acl.rule
      for acl in std.sort($.authelia.access_control, function(x) x.order)
    ],
    oidc_clients:: [
      {
        audience: [],
        authorization_policy: std.extVar('secrets').authelia.oidc.client[client_name].authorization_policy,
        client_name: client_name,
        client_id: client_name,
        grant_types: ['refresh_token', 'authorization_code'],
        public: false,
        redirect_uris: std.extVar('secrets').authelia.oidc.client[client_name].redirect_uris,
        response_modes: ['form_post', 'query', 'fragment'],
        response_types: ['code'],
        scopes: ['openid', 'groups', 'email', 'profile', 'offline_access'],
        userinfo_signed_response_alg: 'none',
        token_endpoint_auth_method: std.extVar('secrets').authelia.oidc.client[client_name].token_endpoint_auth_method,
        client_secret: std.extVar('secrets').authelia.oidc.client[client_name].client_secret,
        [if std.get(std.extVar('secrets').authelia.oidc.client[client_name], 'claims_policy') != null then 'claims_policy']: std.extVar('secrets').authelia.oidc.client[client_name].claims_policy,
      }
      for client_name in std.objectFields(std.extVar('secrets').authelia.oidc.client)
    ],
    service: s.new('authelia', { 'app.kubernetes.io/name': 'authelia' }, [v1.servicePort.withPort(9091) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('authelia')])
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'authelia' }),
    ingress_route: $._custom.ingress_route.new('authelia', 'home-infra', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`auth.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'authelia', port: 9091 }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    config: v1.configMap.new('authelia-config', {
              'users.yml': std.manifestYamlDoc({
                users: std.extVar('secrets').authelia.users,
              }),
              'configuration.yml': std.manifestYamlDoc(std.mergePatch({
                identity_providers: {
                  oidc: {
                    enable_client_debug_messages: false,
                    claims_policies: {
                      default: {
                        id_token: ['groups', 'email', 'email_verified', 'alt_emails', 'preferred_username', 'name'],
                      },
                    },
                    lifespans: { refresh_token: '90m', authorize_code: '1m', id_token: '1h', access_token: '1h' },
                    authorization_policies: std.extVar('secrets').authelia.oidc.authorization_policies,
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
                  expiration: 3600,
                  remember_me: 2592000,
                  cookies: [
                    { domain: std.extVar('secrets').domain, authelia_url: std.format('https://auth.%s', std.extVar('secrets').domain) },
                  ],
                },
                log: {
                  level: 'info',
                  format: 'json',
                },
                notifier: {
                  disable_startup_check: true,
                  smtp: {
                    address: std.format('smtp://%s:%d', [std.extVar('secrets').smtp.server, std.extVar('secrets').smtp.port]),
                    username: std.extVar('secrets').smtp.username,
                    password: std.extVar('secrets').smtp.password,
                    sender: std.format('auth@%s', std.extVar('secrets').domain),
                    subject: '[Authelia] {title}',
                  },
                },
                telemetry: {
                  metrics: { enabled: true },
                },
                storage: {
                  mysql: {
                    address: 'tcp://mariadb.home-infra',
                    database: 'authelia',
                    username: 'authelia',
                    password: std.extVar('secrets').authelia.db.password,
                  },
                },
                access_control: {
                  default_policy: 'deny',
                  rules: $.authelia.access_control_rendered,
                },
                regulation: {
                  max_retries: 3,
                  find_time: 300,
                  ban_time: 900,
                },
                webauthn: {
                  disable: false,
                },
                server: {
                  buffers: {
                    read: 16384,
                    write: 16384,
                  },
                  address: 'tcp://0.0.0.0:9091',
                },
              }, std.extVar('secrets').authelia.config)),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('authelia',
                      1,
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
                        + c.resources.withRequests({ memory: '196Mi', cpu: '80m' })
                        + c.resources.withLimits({ memory: '196Mi', cpu: '80m' })
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'authelia' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.configVolumeMount('authelia-config', '/config', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.spec.withEnableServiceLinks(false)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9959',
                  'fluentbit.io/parser': 'json',
                }),
  },
}
