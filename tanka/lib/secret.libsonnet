{
  secret_restic_password: {
    [std.format('restic_secrets_%s', repo_name)]: $.k.core.v1.secret.new(std.format('restic-secrets-%s', repo_name), {
                                                    RESTIC_PASSWORD: std.base64(std.extVar('secrets').restic.repo[repo_name].password),
                                                  })
                                                  + $.k.core.v1.secret.metadata.withNamespace('kube-system')
                                                  + $.k.core.v1.secret.metadata.withAnnotations({
                                                    'reflector.v1.k8s.emberstack.com/reflection-auto-enabled': 'true',
                                                    'reflector.v1.k8s.emberstack.com/reflection-allowed': 'true',
                                                  })
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
  },
  secret_restic_ssh: {
    [std.format('restic_ssh_%s', repo_name)]: $.k.core.v1.secret.new(std.format('restic-ssh-%s', repo_name), {
                                                id_rsa: std.base64(std.extVar('secrets').restic.repo[repo_name].ssh_key),
                                                config: std.base64(std.extVar('secrets').restic.repo[repo_name].ssh_config),
                                              })
                                              + $.k.core.v1.secret.metadata.withNamespace('kube-system')
                                              + $.k.core.v1.secret.metadata.withAnnotations({
                                                'reflector.v1.k8s.emberstack.com/reflection-auto-enabled': 'true',
                                                'reflector.v1.k8s.emberstack.com/reflection-allowed': 'true',
                                              })
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
    if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false
  },
}
