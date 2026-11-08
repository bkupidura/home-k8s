{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  cilium+: {
    policy+: {
      traefik+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'kitsune', 'io.kubernetes.pod.namespace': 'self-hosted' } }], toPorts: [{ ports: [{ port: '8080', protocol: 'TCP' }] }] },
        ],
      },
      mariadb+: {
        ingress+:: [
          { fromEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'kitsune', 'io.kubernetes.pod.namespace': 'self-hosted' } }], toPorts: [{ ports: [{ port: '3306', protocol: 'TCP' }] }] },
        ],
      },
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'kitsune', 'io.kubernetes.pod.namespace': 'self-hosted' } }], toPorts: [{ ports: [{ port: '8080', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'kitsune',
        rules: [
          {
            alert: 'KitsuneAWSErrors',
            expr: 'increase(kitsune_aws_errors_total[30m]) > 3',
            labels: { service: 'kitsune', severity: 'warning' },
            annotations: {
              summary: 'kitsune is seeing repeated AWS API errors ({{ $labels.operation }}) on {{ $labels.pod }}',
            },
          },
          {
            alert: 'KitsuneSQSBacklog',
            expr: 'kitsune_sqs_messages > 0',
            'for': '10m',
            labels: { service: 'kitsune', severity: 'warning' },
            annotations: {
              summary: 'kitsune inbound SQS queue {{ $labels.queue }} has {{ $value }} unprocessed messages',
            },
          },
          {
            alert: 'KitsuneS3Backlog',
            expr: 'kitsune_s3_objects > 0',
            'for': '15m',
            labels: { service: 'kitsune', severity: 'warning' },
            annotations: {
              summary: 'kitsune has {{ $value }} unprocessed objects in bucket {{ $labels.bucket }}',
            },
          },
          {
            alert: 'KitsuneElevatedDropRate',
            expr: 'increase(kitsune_mail_dropped_total[30m]) > 0',
            labels: { service: 'kitsune', severity: 'warning' },
            annotations: {
              summary: 'kitsune dropped {{ $value }} messages on {{ $labels.pod }} (reason: {{ $labels.reason }})',
            },
          },
          {
            alert: 'KitsuneGeodataFetchFailed',
            expr: 'increase(kitsune_geodata_fetch_errors_total[30m]) > 0',
            labels: { service: 'kitsune', severity: 'warning' },
            annotations: {
              summary: 'kitsune failed to fetch geodata for {{ $labels.country }} on {{ $labels.pod }} (reason: {{ $labels.reason }})',
            },
          },
        ],
      },
    ],
  },
  authelia+: {
    access_control+:: [
      {
        order: 0,
        rule: {
          domain: [
            std.format('kitsune.%s', std.extVar('secrets').domain),
          ],
          resources: ['^/api/'],
          policy: 'bypass',
        },
      },
      {
        order: 1,
        rule: {
          domain: [
            std.format('kitsune.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:kitsune',
          policy: 'one_factor',
        },
      },
    ],
  },
  kitsune: {
    network_policy: $._custom.cilium_network_policy.new(
      'kitsune',
      'self-hosted',
      { matchLabels: { 'app.kubernetes.io/name': 'kitsune' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8080', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '8080', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          toPorts: [
            { ports: [{ port: '53', protocol: 'ANY' }], rules: { dns: [{ matchPattern: '*' }] } },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'mariadb', 'io.kubernetes.pod.namespace': 'home-infra' } },
          ],
          toPorts: [
            { ports: [{ port: '3306', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    ingress_route: $._custom.ingress_route.new('kitsune', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`kitsune.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'kitsune', port: 8080 }],
        middlewares: [
          { name: 'lan-whitelist', namespace: 'traefik-system' },
          { name: 'x-forwarded-proto-https', namespace: 'traefik-system' },
          { name: 'auth-authelia', namespace: 'traefik-system' },
        ],
      },
    ], true),
    service: s.new('kitsune',
                   { 'app.kubernetes.io/name': 'kitsune' },
                   [
                     v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http'),
                   ])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'kitsune' }),
    config: v1.configMap.new('kitsune-config', {
              'config.yaml': std.manifestYamlDoc({
                server: { host: '0.0.0.0', port: 8080 },
                auth: { header: 'Remote-User' },
                domains: std.extVar('secrets').kitsune.domains,
                identity: { locales: ['pl_PL', 'en_US', 'de_DE'] },
                aws: {
                  enabled: true,
                  region: 'eu-central-1',
                  ses: {
                    receipt_rule_set: 'kitsune-ruleset',
                    receipt_rule_prefix: 'kitsune-aliases-',
                    forward_from: std.format('no-reply@%s', std.extVar('secrets').kitsune.domains[0]),
                    sns_topic_arn: std.format('arn:aws:sns:eu-central-1:%s:kitsune-inbound', std.extVar('secrets').kitsune.aws.account_id),
                  },
                  s3: {
                    bucket: std.format('kitsune-inbound-%s', std.extVar('secrets').kitsune.aws.account_id),
                    prefix: 'inbound/',
                  },
                  sqs: {
                    queue_url: std.format('https://sqs.eu-central-1.amazonaws.com/%s/kitsune-inbound', std.extVar('secrets').kitsune.aws.account_id),
                    dlq_url: std.format('https://sqs.eu-central-1.amazonaws.com/%s/kitsune-inbound-dlq', std.extVar('secrets').kitsune.aws.account_id),
                    wait_seconds: 20,
                    max_messages: 10,
                  },
                },
                hero_sms: {
                  enabled: true,
                  max_per_user: 1,
                  max_total: 3,
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('self-hosted'),
    secret: v1.secret.new('kitsune-secrets', {
              AWS_ACCESS_KEY_ID: std.base64(std.extVar('secrets').kitsune.aws.access_key_id),
              AWS_SECRET_ACCESS_KEY: std.base64(std.extVar('secrets').kitsune.aws.secret_access_key),
              KITSUNE_DATABASE_URL: std.base64(std.extVar('secrets').kitsune.db.url),
              KITSUNE_SESSION_SECRET: std.base64(std.extVar('secrets').kitsune.session_secret),
              KITSUNE_HERO_SMS_API_KEY: std.base64(std.extVar('secrets').kitsune.hero_sms.key),
            })
            + v1.secret.metadata.withNamespace('self-hosted'),
    deployment: d.new('kitsune',
                      1,
                      [
                        c.new('kitsune', std.format('registry.%s/kitsune:0.4c', std.extVar('secrets').domain))
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8080, 'http'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          KITSUNE_CONFIG: '/config/config.yaml',
                        })
                        + c.withEnvFrom(v1.envFromSource.secretRef.withName('kitsune-secrets'))
                        + c.resources.withRequests({ memory: '80M', cpu: '45m' })
                        + c.resources.withLimits({ memory: '200M', cpu: '90m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.withRunAsNonRoot(true)
                        + c.securityContext.withRunAsUser(10001)
                        + c.securityContext.withRunAsGroup(10001)
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.httpGet.withPath('/healthz')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(3)
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(15)
                        + c.livenessProbe.withPeriodSeconds(15)
                        + c.livenessProbe.withTimeoutSeconds(3),
                      ],
                      { 'app.kubernetes.io/name': 'kitsune' })
                + d.metadata.withAnnotations({ 'reloader.stakater.com/auto': 'true' })
                + d.configVolumeMount('kitsune-config', '/config/', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.spec.template.spec.withAutomountServiceAccountToken(false)
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '8080',
                })
                + d.metadata.withNamespace('self-hosted'),
  },
}
