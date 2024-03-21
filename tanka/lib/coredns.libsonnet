{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  coredns: {
    kubelet_cluster_dns:: '10.43.0.10',
    service_account: $.k.core.v1.serviceAccount.new('coredns')
                     + $.k.core.v1.serviceAccount.metadata.withNamespace('kube-system'),
    cluster_role: $.k.rbac.v1.clusterRole.new('system:coredns')
                  + $.k.rbac.v1.clusterRole.withRules([
                    $.k.rbac.v1.policyRule.withApiGroups('')
                    + $.k.rbac.v1.policyRule.withResources(['endpoints', 'services', 'pods', 'namespaces'])
                    + $.k.rbac.v1.policyRule.withVerbs(['list', 'watch']),
                    $.k.rbac.v1.policyRule.withApiGroups('discovery.k8s.io')
                    + $.k.rbac.v1.policyRule.withResources(['endpointslices'])
                    + $.k.rbac.v1.policyRule.withVerbs(['list', 'watch']),
                  ]),
    cluster_role_binding: $.k.rbac.v1.clusterRoleBinding.new('system:coredns')
                          + $.k.rbac.v1.clusterRoleBinding.bindRole(
                            $.k.rbac.v1.clusterRole.new('system:coredns')
                          )
                          + $.k.rbac.v1.clusterRoleBinding.withSubjects(
                            [
                              $.k.rbac.v1.subject.withName('coredns')
                              + $.k.rbac.v1.subject.withNamespace('kube-system')
                              + $.k.rbac.v1.subject.withKind('ServiceAccount'),
                            ]
                          ),
    config: v1.configMap.new('coredns', {
              Corefile: |||
                .:53 {
                    errors
                    health
                    ready
                    kubernetes cluster.local in-addr.arpa ip6.arpa {
                        pods insecure
                        fallthrough in-addr.arpa ip6.arpa
                    }
                    prometheus :9153
                    forward home %(upstream_server)s:53
                    forward %(domain)s %(upstream_server)s:53
                    forward . 127.0.0.1:5301 127.0.0.1:5302
                    loop
                    reload
                    loadbalance
                }
                .:5301 {
                    forward . tls://9.9.9.9 {
                        tls_servername dns.quad9.net
                    }
                    cache 600
                }
                .:5302 {
                    forward . tls://1.1.1.1 tls://1.0.0.1 {
                         tls_servername cloudflare-dns.com
                    }
                    cache 600
                }
              ||| % { upstream_server: $._config.upstream_dns, domain: std.extVar('secrets').domain},
            })
            + v1.configMap.metadata.withNamespace('kube-system'),
    service: s.new('kube-dns', { 'app.kubernetes.io/name': 'coredns' }, [
               v1.servicePort.withPort(53) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('dns-tcp'),
               v1.servicePort.withPort(53) + v1.servicePort.withProtocol('UDP') + v1.servicePort.withName('dns'),
               v1.servicePort.withPort(9153) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('metrics'),
             ])
             + s.spec.withClusterIP($.coredns.kubelet_cluster_dns)
             + s.metadata.withNamespace('kube-system')
             + s.metadata.withAnnotations({ 'prometheus.io/port': '9153', 'prometheus.io/scrape': 'true' })
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'coredns' }),
    deployment: d.new('coredns',
                      2,
                      [
                        c.new('coredns', $._version.coredns.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withArgs(['-conf', '/etc/coredns/Corefile'])
                        + c.withPorts([
                          v1.containerPort.newNamedUDP(53, 'dns'),
                          v1.containerPort.newNamed(53, 'dns-tcp'),
                          v1.containerPort.newNamed(9153, 'metrics'),
                        ])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.resources.withRequests({ memory: '64Mi', cpu: '100m' })
                        + c.resources.withLimits({ memory: '96Mi' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.securityContext.capabilities.withAdd('NET_BIND_SERVICE')
                        + c.securityContext.capabilities.withDrop('all')
                        + c.readinessProbe.httpGet.withPath('/ready')
                        + c.readinessProbe.httpGet.withPort(8181)
                        + c.livenessProbe.httpGet.withPath('/health')
                        + c.livenessProbe.httpGet.withPort(8080)
                        + c.livenessProbe.withInitialDelaySeconds(60)
                        + c.livenessProbe.withTimeoutSeconds(5)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withFailureThreshold(5),
                      ],
                      { 'app.kubernetes.io/name': 'coredns' })
                + d.configVolumeMount('coredns', '/etc/coredns/', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.spec.template.spec.withDnsPolicy('Default')
                + d.spec.template.spec.withPriorityClassName('system-cluster-critical')
                + d.spec.template.spec.withServiceAccountName('coredns')
                + d.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                  v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['coredns'] }
                  )
                )
                + d.metadata.withNamespace('kube-system')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
