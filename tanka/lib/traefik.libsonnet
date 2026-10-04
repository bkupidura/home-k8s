{
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } }], toPorts: [{ ports: [{ port: '9100', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  logging+: {
    parsers+:: {
      traefik: |||
        [PARSER]
            name traefik
            format json
            time_key time
            time_format %Y-%m-%dT%H:%M:%S%z
      |||,
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'traefik',
        rules: [
          {
            alert: 'TraefikServiceErrors5XX',
            expr: 'sum by (service, protocol) (delta(traefik_service_requests_total{code=~"5.."}[5m])) / sum by(service, protocol) (delta(traefik_service_requests_total{code!~"(4|5).."}[5m])) > 0.1',
            'for': '10m',
            labels: { service: 'traefik', severity: 'warning' },
            annotations: {
              summary: 'Traefik service requests error (5XX) increase for {{ $labels.protocol }}/{{ $labels.service }}',
            },
          },
        ],
      },
    ],
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('traefik.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:admin',
          policy: 'one_factor',
        },
      },
    ],
  },
  traefik: {
    namespace: $.k.core.v1.namespace.new('traefik-system'),
    network_policy: $._custom.cilium_network_policy.new(
      'traefik',
      'traefik-system',
      { matchLabels: { 'app.kubernetes.io/name': 'traefik' } },
      ingress=[
        {
          fromCIDR: [
            $._config.network.lan,
            $._config.network.iot,
            $._config.network.mgmt,
            $._config.network.guest,
            $._config.network.vpn,
          ],
          toPorts: [
            { ports: [{ port: '8000', protocol: 'TCP' }, { port: '8443', protocol: 'TCP' }] },
          ],
        },
        {
          fromCIDR: [
            $._config.network.lan,
            $._config.network.iot,
            $._config.network.mgmt,
            $._config.network.guest,
            $._config.network.vpn,
          ],
          icmps: [
            { fields: [{ family: 'IPv4', type: 'DestinationUnreachable' }] },
          ],
        },
        {
          fromEntities: ['host', 'remote-node'],
          toPorts: [
            { ports: [{ port: '8443', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9100', protocol: 'TCP' }] },
          ],
        },
      ] + std.get($.cilium.policy.traefik, 'ingress', []),
      egress=[
        {
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'coredns', 'io.kubernetes.pod.namespace': 'kube-system' } },
          ],
          toPorts: [
            { ports: [{ port: '53', protocol: 'ANY' }], rules: { dns: [{ matchPattern: '*' }] } },
          ],
        },
      ] + std.get($.cilium.policy.traefik, 'egress', []),
    ),
    helm: $._custom.helm.new('traefik', 'traefik', 'https://helm.traefik.io/traefik', $._version.traefik.chart, 'traefik-system', {
      resources: {
        requests: { cpu: '200m', memory: '120Mi' },
        limits: { cpu: '200m', memory: '120Mi' },
      },
      image: { registry: $._version.traefik.registry, repository: $._version.traefik.repo, tag: $._version.traefik.tag },
      env: [
        { name: 'TZ', value: $._config.tz },
      ],
      affinity: {
        podAntiAffinity: {
          requiredDuringSchedulingIgnoredDuringExecution: [
            {
              labelSelector: {
                matchExpressions: [
                  {
                    key: 'app.kubernetes.io/name',
                    operator: 'In',
                    values: ['traefik'],
                  },
                ],
              },
              topologyKey: 'kubernetes.io/hostname',
            },
          ],
        },
      },
      deployment: {
        enabled: true,
        replicas: 2,
        podAnnotations: {
          'prometheus.io/scrape': 'true',
          'prometheus.io/port': '9100',
          'fluentbit.io/parser': 'traefik',
        },
      },
      persistence: { enabled: false },
      additionalArguments: [
        '--global.checkNewVersion=false',
        '--global.sendAnonymousUsage=false',
        '--accesslog',
        '--accesslog.format=json',
        '--accesslog.fields.headers.defaultmode=redact',
        '--serversTransport.insecureSkipVerify=true',
        '--serversTransport.maxIdleConnsPerHost=20',
        '--serversTransport.forwardingTimeouts.idleConnTimeout=300s',
        std.format('--entryPoints.web.forwardedHeaders.trustedIPs=%s', $._config.network.kubernetes),
        std.format('--entryPoints.websecure.forwardedHeaders.trustedIPs=%s', $._config.network.kubernetes),
        '--entryPoints.web.http.aliasHeadersStrategy=reject',
        '--entryPoints.websecure.http.aliasHeadersStrategy=reject',
        '--log',
        '--log.level=INFO',
        '--log.format=json',
        '--metrics.prometheus=true',
      ],
      ports: {
        traefik: { expose: { default: false } },
        web: {
          expose: { default: true },
          transport: {
            respondingTimeouts: { readTimeout: 240, writeTimeout: 0, idleTimeout: 180 },
          },
        },
        websecure: {
          expose: { default: true },
          transport: {
            respondingTimeouts: { readTimeout: 240, writeTimeout: 0, idleTimeout: 180 },
          },
        },
      },
      providers: {
        kubernetesCRD: {
          enabled: true,
          allowCrossNamespace: true,
          safeNaming: true,
        },
        kubernetesIngress: {
          enabled: true,
        },
      },
      ingressRoute: {
        dashboard: { enabled: false },
      },
      service: {
        spec: {
          externalTrafficPolicy: 'Local',
        },
        annotations: {
          'lbipam.cilium.io/ips': $._config.vip.ingress,
        },
      },
    }),
    middleware_whitelist: {
      [std.format('whitelist_%s', whitelist_name)]: $._custom.traefik_middleware.new(std.format('%s-whitelist', whitelist_name), {
        ipAllowList: {
          sourceRange: $._config.traefik.whitelist[whitelist_name],
        },
      })
      for whitelist_name in std.objectFields($._config.traefik.whitelist)
    },
    middleware_x_forward_proto_https: $._custom.traefik_middleware.new('x-forwarded-proto-https', {
      headers: {
        customRequestHeaders: {
          'X-Forwarded-Proto': 'https',
        },
      },
    }),
    middleware_auth_authelia: $._custom.traefik_middleware.new('auth-authelia', {
      forwardAuth: {
        address: 'http://authelia.home-infra:9091/api/authz/forward-auth',
        trustForwardHeader: true,
        authResponseHeaders: [
          'Remote-User',
          'Remote-Name',
          'Remote-Email',
          'Remote-Groups',
        ],
        maxResponseBodySize: 65536,
      },
    }),
    tls_store: {
      apiVersion: 'traefik.io/v1alpha1',
      kind: 'TLSStore',
      metadata: {
        name: 'default',
        namespace: 'traefik-system',
      },
      spec: {
        defaultCertificate: {
          secretName: std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls',
        },
      },
    },
    ingress_route: $._custom.ingress_route.new('traefik-dashboard', 'traefik-system', ['websecure'], [
      {
        match: std.format('Host(`traefik.%s`)', std.extVar('secrets').domain),
        kind: 'Rule',
        services: [
          {
            name: 'api@internal',
            kind: 'TraefikService',
          },
        ],
        middlewares: [
          { name: 'lan-whitelist', namespace: 'traefik-system' },
          { name: 'auth-authelia', namespace: 'traefik-system' },
        ],
      },
    ], true),
  },
}
