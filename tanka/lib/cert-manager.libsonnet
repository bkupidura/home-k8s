{
  prometheus+: {
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
    secret: $.k.core.v1.secret.new('cert-manager', {
              secret_key: std.base64(std.extVar('secrets').cert_manager.secret_key),
            })
            + $.k.core.v1.secret.metadata.withNamespace('cert-manager'),
    helm: $._custom.helm.new('cert-manager', 'https://charts.jetstack.io', $._version.cert_manager.chart, 'cert-manager', {
      image: { repository: $._version.cert_manager.repo, tag: $._version.cert_manager.tag },
      extraEnv: [
        { name: 'TZ', value: $._config.tz },
      ],
      extraArgs: [
        '--dns01-recursive-nameservers-only',
        '--dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53',
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
        requests: { memory: '32Mi' },
        limits: { memory: '64Mi' },
      },
      cainjector: {
        requests: { memory: '64Mi' },
        limits: { memory: '128Mi' },
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
                route53: {
                  region: 'us-east-1',
                  accessKeyID: std.extVar('secrets').cert_manager.access_key,
                  secretAccessKeySecretRef: { key: 'secret_key', name: 'cert-manager' },
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
          },
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
