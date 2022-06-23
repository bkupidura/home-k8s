{
  k8s_dashboard: {
    service_account: $.k.core.v1.serviceAccount.new('admin-user')
                     + $.k.core.v1.serviceAccount.metadata.withNamespace('kube-system'),
    cluster_role_binding: $.k.rbac.v1.clusterRoleBinding.new('admin-user')
                          + $.k.rbac.v1.clusterRoleBinding.bindRole(
                            $.k.rbac.v1.clusterRole.new('cluster-admin')
                          )
                          + $.k.rbac.v1.clusterRoleBinding.withSubjects(
                            [
                              $.k.rbac.v1.subject.withName('admin-user')
                              + $.k.rbac.v1.subject.withNamespace('kube-system')
                              + $.k.rbac.v1.subject.withKind('ServiceAccount'),
                            ]
                          ),
    ingress_route: $._custom.ingress_route.new('k8s-dashboard', 'kube-system', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`k8s.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'kubernetes-dashboard', port: 443, namespace: 'kube-system' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }],
      },
    ], true),
    helm: $._custom.helm.new('kubernetes-dashboard', 'https://kubernetes.github.io/dashboard/', $._version.kubernetes_dashboard.chart, 'kube-system', {
      resources: {
        requests: { cpu: '30m', memory: '32Mi' },
        limits: { cpu: '50m', memory: '64Mi' },
      },
    }),
  },
}
