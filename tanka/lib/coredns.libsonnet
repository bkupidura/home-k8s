{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  monitoring+: {
    rules+:: [
      {
        name: 'coredns',
        rules: [
          {
            alert: 'CoreDNSReloadFailures',
            expr: 'delta(coredns_reload_failed_total[10m]) > 0',
            labels: { service: 'coredns', severity: 'warning' },
            annotations: {
              summary: 'Failed to reload config on {{ $labels.pod }}',
            },
          },
          {
            alert: 'CoreDNSPanic',
            expr: 'delta(coredns_panics_total[10m]) > 0',
            labels: { service: 'coredns', severity: 'warning' },
            annotations: {
              summary: 'Panics observed on {{ $labels.pod }}',
            },
          },
          {
            alert: 'CoreDNSKubernetesRequests',
            expr: 'delta(coredns_kubernetes_rest_client_requests_total{code!="200"}[15m]) > 5',
            labels: { service: 'coredns', severity: 'warning' },
            annotations: {
              summary: 'K8s requestes failing observed on {{ $labels.pod }}',
            },
          },
          {
            alert: 'CoreDNSEmptyCache',
            expr: 'sum by(pod, type) (coredns_cache_entries) == 0',
            labels: { service: 'coredns', severity: 'warning' },
            annotations: {
              summary: 'Empty cache on {{ $labels.pod }} for {{ $labels.type }}',
            },
          },
        ],
      },
    ],
  },
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
    forward_snippet:: |||
      forward %(domain)s %(server)s
    |||,
    forward_config:: [
      $.coredns.forward_snippet % forward
      for forward in std.extVar('secrets').coredns.forward
    ],
    zone: v1.configMap.new('coredns-zones', {
            [std.format('%s.db', domain)]: std.extVar('secrets').coredns.zone[domain]
            for domain in std.objectFields(std.extVar('secrets').coredns.zone)
          })
          + v1.configMap.metadata.withNamespace('kube-system'),
    zone_config_snippet:: |||
      %(domain)s:53 {
          errors
          file /etc/coredns/zones/%(domain)s.db
      }
    |||,
    zone_config:: [
      $.coredns.zone_config_snippet % { domain: domain }
      for domain in std.objectFields(std.extVar('secrets').coredns.zone)
    ],
    config: v1.configMap.new('coredns', {
              Corefile: |||
                %(zone)s
                .:53 {
                    errors
                    health
                    ready
                    prometheus :9153
                    loop
                    reload
                    loadbalance
                    kubernetes cluster.local in-addr.arpa ip6.arpa {
                        pods insecure
                        fallthrough in-addr.arpa ip6.arpa
                    }
                    %(forwards)s
                    forward . 127.0.0.1:5301 127.0.0.1:5302
                }
                .:5301 {
                    forward . tls://9.9.9.9 {
                        tls_servername dns.quad9.net
                    }
                    cache 600 . {
                        success 3000
                        denial 500
                        prefetch 10 300s
                        servfail 10s
                    }
                }
                .:5302 {
                    forward . tls://1.1.1.1 tls://1.0.0.1 {
                         tls_servername cloudflare-dns.com
                    }
                    cache 600 . {
                        success 3000
                        denial 500
                        prefetch 10 300s
                        servfail 10s
                    }
                }
              ||| % { forwards: std.join('\n', $.coredns.forward_config), zone: std.join('\n', $.coredns.zone_config) },
            })
            + v1.configMap.metadata.withNamespace('kube-system'),
    service: s.new('kube-dns', { 'app.kubernetes.io/name': 'coredns' }, [
               v1.servicePort.withPort(53) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('dns-tcp'),
               v1.servicePort.withPort(53) + v1.servicePort.withProtocol('UDP') + v1.servicePort.withName('dns'),
             ])
             + s.spec.withClusterIP($.coredns.kubelet_cluster_dns)
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false)
             + s.metadata.withNamespace('kube-system')
             + s.metadata.withAnnotations({ 'metallb.io/loadBalancerIPs': $._config.vip.core_dns })
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
                        + c.resources.withLimits({ memory: '128Mi' })
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
                + d.configVolumeMount('coredns-zones', '/etc/coredns/zones/', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.spec.template.spec.withDnsPolicy('Default')
                + d.spec.template.spec.withPriorityClassName('system-cluster-critical')
                + d.spec.template.spec.withServiceAccountName('coredns')
                + d.spec.template.metadata.withAnnotations({
                  'prometheus.io/scrape': 'true',
                  'prometheus.io/port': '9153',
                })
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
