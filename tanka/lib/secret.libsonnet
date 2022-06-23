{
  secret: {
    restic_secrets: $.k.core.v1.secret.new('restic-secrets', {
                      RESTIC_PASSWORD: std.base64(std.extVar('secrets').restic.password),
                    })
                    + $.k.core.v1.secret.metadata.withNamespace('kube-system')
                    + $.k.core.v1.secret.metadata.withAnnotations({
                      'reflector.v1.k8s.emberstack.com/reflection-auto-enabled': 'true',
                      'reflector.v1.k8s.emberstack.com/reflection-allowed': 'true',
                    }),
  },
}
