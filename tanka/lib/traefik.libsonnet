{
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
  traefik: {
    namespace: $.k.core.v1.namespace.new('traefik-system'),
    helm: $._custom.helm.new('traefik', 'https://helm.traefik.io/traefik', $._version.traefik.chart, 'traefik-system', {
      resources: {
        requests: { cpu: '150m', memory: '96Mi' },
        limits: { cpu: '150m', memory: '96Mi' },
      },
      image: { name: $._version.traefik.repo, tag: $._version.traefik.tag },
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
        replicas: 1,
        podAnnotations: {
          'prometheus.io/scrape': 'true',
          'prometheus.io/port': '9100',
          'fluentbit.io/parser': 'traefik',
        },
      },
      persistence: { enabled: false },
      additionalArguments: [
        '--accesslog',
        '--accesslog.format=json',
        '--serversTransport.insecureSkipVerify=true',
        std.format('--entryPoints.web.forwardedHeaders.trustedIPs=%s', $._config.kubernetes_internal_cidr),
        std.format('--entryPoints.websecure.forwardedHeaders.trustedIPs=%s', $._config.kubernetes_internal_cidr),
        '--log',
        '--log.level=INFO',
        '--log.format=json',
        '--metrics.prometheus=true',
        '--providers.kubernetescrd.allowCrossNamespace=true',
      ],
      ports: {
        traefik: { expose: { default: false } },
        web: { expose: { default: true } },
        websecure: { expose: { default: true } },
      },
      providers: {
        kubernetesCRD: {
          enabled: true,
          allowCrossNamespace: true,
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
          loadBalancerIP: $._config.vip.ingress,
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
        address: 'http://authelia.home-infra:9091/api/verify?rd=https://auth.' + std.extVar('secrets').domain,
        trustForwardHeader: true,
        authResponseHeaders: [
          'Remote-User',
          'Remote-Name',
          'Remote-Email',
          'Remote-Groups',
        ],
      },
    }),
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
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
  },
}
