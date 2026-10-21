{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  local perses_dashboards = {
    monitoring: import 'perses/monitoring.libsonnet',
    falco: import 'perses/falco.libsonnet',
    waf: import 'perses/waf.libsonnet',
    'smart-home': import 'perses/smart-home.libsonnet',
    ups: import 'perses/ups.libsonnet',
    'node-exporter': import 'perses/node-exporter.libsonnet',
    'k8s-pod': import 'perses/k8s-pod.libsonnet',
    'k8s-workload': import 'perses/k8s-workload.libsonnet',
    truenas: import 'perses/truenas.libsonnet',
  },
  local mkDashboard(dashboard) = {
    kind: 'Dashboard',
    metadata: {
      name: dashboard.metadata.name,
      project: 'Home-lab',
    },
    spec: dashboard.spec,
  },
  local dashboard_cm_name(name) = std.format('perses-dash-%s', name),
  local dashboard_cm_names = [dashboard_cm_name(name) for name in std.objectFields(perses_dashboards)],
  local reloader_configmaps = std.join(',', ['perses-config', 'perses-prov-base'] + dashboard_cm_names),
  cilium+: {
    policy+: {
      traefik+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'perses', 'io.kubernetes.pod.namespace': 'monitoring' } }], toPorts: [{ ports: [{ port: '8080', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('perses.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:admin',
          policy: 'one_factor',
        },
      },
    ],
  },
  perses: {
    network_policy: $._custom.cilium_network_policy.new(
      'perses',
      'monitoring',
      { matchLabels: { 'app.kubernetes.io/name': 'perses' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'traefik', 'io.kubernetes.pod.namespace': 'traefik-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8080', protocol: 'TCP' }] },
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
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '8428', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-logs-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    service: s.new(
               'perses',
               { 'app.kubernetes.io/name': 'perses' },
               [v1.servicePort.withPort(8080) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')]
             )
             + s.metadata.withNamespace('monitoring')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'perses' }),
    ingress_route: $._custom.ingress_route.new('perses', 'monitoring', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`perses.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'perses', port: 8080, namespace: 'monitoring' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], true),
    config: v1.configMap.new('perses-config', {
              'config.yaml': std.manifestYamlDoc({
                database: {
                  file: {
                    folder: '/perses/data',
                    extension: 'json',
                  },
                },
                provisioning: {
                  folders: ['/etc/perses/provisioning'],
                },
                frontend: {
                  explorer: {
                    enable: true,
                  },
                  time_range: {
                    options: ['5m', '15m', '30m', '1h', '3h', '6h', '12h', '1d', '1w'],
                    disable_custom: false,
                  },
                },
              }),
            })
            + v1.configMap.metadata.withNamespace('monitoring'),
    provisioning_base: v1.configMap.new('perses-prov-base', {
                         'project.yaml': std.manifestYamlDoc({
                           kind: 'Project',
                           metadata: { name: 'Home-lab' },
                           spec: { display: { name: 'Home-lab' } },
                         }),
                         'folder-k8s.yaml': std.manifestYamlDoc({
                           kind: 'Folder',
                           metadata: { name: 'K8s', project: 'Home-lab' },
                           spec: {
                             display: { name: 'K8s' },
                             items: [
                               { kind: 'Dashboard', name: perses_dashboards['k8s-pod'].metadata.name },
                               { kind: 'Dashboard', name: perses_dashboards['k8s-workload'].metadata.name },
                             ],
                           },
                         }),
                         'folder-infra.yaml': std.manifestYamlDoc({
                           kind: 'Folder',
                           metadata: { name: 'infra', project: 'Home-lab' },
                           spec: {
                             display: { name: 'Infra' },
                             items: [
                               { kind: 'Dashboard', name: perses_dashboards['node-exporter'].metadata.name },
                               { kind: 'Dashboard', name: perses_dashboards.truenas.metadata.name },
                               { kind: 'Dashboard', name: perses_dashboards.ups.metadata.name },
                             ],
                           },
                         }),
                         'folder-security.yaml': std.manifestYamlDoc({
                           kind: 'Folder',
                           metadata: { name: 'security', project: 'Home-lab' },
                           spec: {
                             display: { name: 'Security' },
                             items: [
                               { kind: 'Dashboard', name: perses_dashboards.falco.metadata.name },
                               { kind: 'Dashboard', name: perses_dashboards.waf.metadata.name },
                             ],
                           },
                         }),
                         'datasource.yaml': std.manifestYamlDoc({
                           kind: 'GlobalDatasource',
                           metadata: { name: 'victoriametrics' },
                           spec: {
                             default: true,
                             plugin: {
                               kind: 'PrometheusDatasource',
                               spec: {
                                 proxy: {
                                   kind: 'HTTPProxy',
                                   spec: {
                                     url: 'http://victoria-metrics-single-server.monitoring.svc:8428',
                                     allowedEndpoints: [
                                       { endpointPattern: '/api/v1/labels', method: 'POST' },
                                       { endpointPattern: '/api/v1/series', method: 'POST' },
                                       { endpointPattern: '/api/v1/metadata', method: 'GET' },
                                       { endpointPattern: '/api/v1/query', method: 'POST' },
                                       { endpointPattern: '/api/v1/query_range', method: 'POST' },
                                       { endpointPattern: '/api/v1/label/.*/values', method: 'GET' },
                                       { endpointPattern: '/api/v1/parse_query', method: 'POST' },
                                     ],
                                   },
                                 },
                               },
                             },
                           },
                         }),
                         'datasource-logs.yaml': std.manifestYamlDoc({
                           kind: 'GlobalDatasource',
                           metadata: { name: 'victorialogs' },
                           spec: {
                             default: true,
                             plugin: {
                               kind: 'VictoriaLogsDatasource',
                               spec: {
                                 proxy: {
                                   kind: 'HTTPProxy',
                                   spec: {
                                     url: 'http://victoria-logs-single-server.monitoring.svc:9428',
                                     allowedEndpoints: std.flattenArrays([
                                       [
                                         { endpointPattern: ep, method: 'GET' },
                                         { endpointPattern: ep, method: 'POST' },
                                       ]
                                       for ep in [
                                         '/select/logsql/query',
                                         '/select/logsql/stats_query',
                                         '/select/logsql/stats_query_range',
                                         '/select/logsql/hits',
                                         '/select/logsql/field_names',
                                         '/select/logsql/field_values',
                                       ]
                                     ]),
                                   },
                                 },
                               },
                             },
                           },
                         }),
                       })
                       + v1.configMap.metadata.withNamespace('monitoring'),
    dashboard_configmaps: {
      [dashboard_cm_name(name)]: v1.configMap.new(dashboard_cm_name(name), {
        [std.format('%s.json', name)]: std.manifestJson(mkDashboard(perses_dashboards[name])),
      }) + v1.configMap.metadata.withNamespace('monitoring')
      for name in std.objectFields(perses_dashboards)
    },
    deployment: d.new('perses',
                      1,
                      [
                        c.new('perses', $._version.perses.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withArgs(['--config=/etc/perses/config.yaml'])
                        + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                        + c.withEnvMap({
                          TZ: $._config.tz,
                        })
                        + c.withVolumeMounts([
                          v1.volumeMount.new('perses-config', '/etc/perses/config.yaml', true) + v1.volumeMount.withSubPath('config.yaml'),
                          v1.volumeMount.new('perses-provisioning', '/etc/perses/provisioning', true),
                          v1.volumeMount.new('perses-plugins', '/etc/perses/plugins'),
                          v1.volumeMount.new('perses-data', '/perses/data'),
                        ])
                        + c.resources.withRequests({ memory: '100M', cpu: '100m' })
                        + c.resources.withLimits({ memory: '200M', cpu: '200m' })
                        + c.securityContext.withAllowPrivilegeEscalation(false)
                        + c.securityContext.capabilities.withDrop('all')
                        + c.securityContext.withReadOnlyRootFilesystem(true)
                        + c.readinessProbe.httpGet.withPath('/api/v1/health')
                        + c.readinessProbe.httpGet.withPort('http')
                        + c.readinessProbe.withInitialDelaySeconds(10)
                        + c.readinessProbe.withPeriodSeconds(10)
                        + c.readinessProbe.withTimeoutSeconds(2)
                        + c.livenessProbe.httpGet.withPath('/api/v1/health')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'perses' })
                + d.metadata.withAnnotations({ 'configmap.reloader.stakater.com/reload': reloader_configmaps })
                + d.spec.template.spec.securityContext.withRunAsNonRoot(true)
                + d.spec.template.spec.securityContext.withRunAsUser(65532)
                + d.spec.template.spec.securityContext.withFsGroup(65532)
                + d.spec.template.spec.withVolumes([
                  v1.volume.fromConfigMap('perses-config', 'perses-config'),
                  {
                    name: 'perses-provisioning',
                    projected: {
                      sources: [{ configMap: { name: 'perses-prov-base' } }]
                               + [{ configMap: { name: cm } } for cm in dashboard_cm_names],
                    },
                  },
                  v1.volume.fromEmptyDir('perses-plugins', emptyDir={ sizeLimit: '500M' }),
                  v1.volume.fromEmptyDir('perses-data', emptyDir={ sizeLimit: '5M' }),
                ])
                + d.spec.strategy.withType('RollingUpdate')
                + d.metadata.withNamespace('monitoring')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(5),
  },
}
