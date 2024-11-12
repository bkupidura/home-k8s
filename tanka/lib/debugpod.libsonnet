{
  local v1 = $.k.core.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  debugpod: {
    deployment: d.new(
                  'debugpod',
                  0,
                  [
                    c.new('debugpod', $._version.ubuntu.image)
                    + c.withImagePullPolicy('IfNotPresent')
                    + c.withCommand([
                      '/bin/sh',
                      '-ec',
                      std.join('\n', ['apt update', 'apt install -y tcpdump python3 vim curl iputils-ping bind9-host atop sysstat powertop iperf fio', 'tail -f /dev/null']),
                    ])
                  ],
                  podLabels={ 'app.kubernetes.io/name': 'debugpod' },
                )
                + d.metadata.withNamespace('home-infra')
                + d.spec.strategy.withType('Recreate')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.spec.withDnsPolicy('ClusterFirstWithHostNet')
                + d.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                  v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                  + v1.podAffinityTerm.labelSelector.withMatchExpressions(
                    { key: 'app.kubernetes.io/name', operator: 'In', values: ['debugpod'] }
                  )
                ),
  },

}
