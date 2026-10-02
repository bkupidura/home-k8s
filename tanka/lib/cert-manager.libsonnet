{
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'cert-manager', 'app.kubernetes.io/instance': 'cert-manager', 'app.kubernetes.io/component': 'controller', 'io.kubernetes.pod.namespace': 'cert-manager' } }], toPorts: [{ ports: [{ port: '9402', protocol: 'TCP' }] }] },
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'webhook', 'app.kubernetes.io/instance': 'cert-manager', 'app.kubernetes.io/component': 'webhook', 'io.kubernetes.pod.namespace': 'cert-manager' } }], toPorts: [{ ports: [{ port: '9402', protocol: 'TCP' }] }] },
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'cainjector', 'app.kubernetes.io/instance': 'cert-manager', 'app.kubernetes.io/component': 'cainjector', 'io.kubernetes.pod.namespace': 'cert-manager' } }], toPorts: [{ ports: [{ port: '9402', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'cert-manager',
        rules: [
          {
            alert: 'CertInvalidShortly',
            expr: '(certmanager_certificate_expiration_timestamp_seconds - time()) / 60 / 60 / 24 < 29',
            labels: { service: 'certmanager', severity: 'info' },
            annotations: {
              summary: 'Certificate will expire soon',
            },
          },
        ],
      },
    ],
  },
  cert_manager: {
    namespace: $.k.core.v1.namespace.new('cert-manager'),
    network_policy_controller: $._custom.cilium_network_policy.new(
      'cert-manager',
      'cert-manager',
      { matchLabels: { 'app.kubernetes.io/name': 'cert-manager', 'app.kubernetes.io/instance': 'cert-manager', 'app.kubernetes.io/component': 'controller' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9402', protocol: 'TCP' }] },
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
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDR: [std.format('%s/32', ns) for ns in $._config.cert_manager.dns01_nameservers],
          toPorts: [
            { ports: [{ port: '53', protocol: 'ANY' }] },
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
    network_policy_webhook: $._custom.cilium_network_policy.new(
      'cert-manager-webhook',
      'cert-manager',
      { matchLabels: { 'app.kubernetes.io/name': 'webhook', 'app.kubernetes.io/instance': 'cert-manager', 'app.kubernetes.io/component': 'webhook' } },
      ingress=[
        {
          fromEntities: ['host', 'remote-node'],
          toPorts: [
            { ports: [{ port: '10250', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9402', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    network_policy_cainjector: $._custom.cilium_network_policy.new(
      'cert-manager-cainjector',
      'cert-manager',
      { matchLabels: { 'app.kubernetes.io/name': 'cainjector', 'app.kubernetes.io/instance': 'cert-manager', 'app.kubernetes.io/component': 'cainjector' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9402', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    secret: $.k.core.v1.secret.new('cert-manager', {
              token: std.base64(std.extVar('secrets').cert_manager.digialocean.token),
            })
            + $.k.core.v1.secret.metadata.withNamespace('cert-manager'),
    helm: $._custom.helm.new('cert-manager', 'cert-manager', 'https://charts.jetstack.io', $._version.cert_manager.chart, 'cert-manager', {
      image: {
        repository: std.splitLimitR($._version.cert_manager.image, ':', 1)[0],
        tag: std.splitLimitR($._version.cert_manager.image, ':', 1)[1],
      },
      extraEnv: [
        { name: 'TZ', value: $._config.tz },
      ],
      extraArgs: [
        '--dns01-recursive-nameservers-only',
        std.format('--dns01-recursive-nameservers=%s', std.join(',', [std.format('%s:53', ns) for ns in $._config.cert_manager.dns01_nameservers])),
      ],
      installCRDs: true,
      prometheus: {
        enabled: true,
        servicemonitor: { enabled: false },
      },
      resources: {
        requests: { memory: '64Mi' },
        limits: { memory: '128Mi' },
      },
      webhook: {
        resources: {
          requests: { memory: '32Mi' },
          limits: { memory: '64Mi' },
        },
      },
      cainjector: {
        resources: {
          requests: { memory: '64Mi' },
          limits: { memory: '128Mi' },
        },
      },
    }),
    issuer: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Issuer',
      metadata: {
        name: 'letsencrypt',
        namespace: 'cert-manager',
      },
      spec: {
        acme: {
          server: 'https://acme-v02.api.letsencrypt.org/directory',
          email: std.extVar('secrets').mail,
          privateKeySecretRef: { name: 'letsencrypt-account-key' },
          solvers: [
            {
              dns01: {
                digitalocean: {
                  tokenSecretRef: {
                    name: 'cert-manager',
                    key: 'token',
                  },
                },
              },
            },
          ],
        },
      },
    },
    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'tls-certificate',
        namespace: 'cert-manager',
      },
      spec: {
        secretTemplate: {
          annotations: {
            'reflector.v1.k8s.emberstack.com/reflection-allowed': 'true',
            'reflector.v1.k8s.emberstack.com/reflection-auto-enabled': 'true',
            'reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces': 'traefik-system,home-infra',
          },
        },
        privateKey: {
          rotationPolicy: 'Always',
        },
        dnsNames: [
          std.extVar('secrets').domain,
          std.format('*.%s', std.extVar('secrets').domain),
        ],
        issuerRef: { name: 'letsencrypt' },
        secretName: std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls',
        renewBefore: '720h',
        duration: '2160h',
      },
    },
  },
}
