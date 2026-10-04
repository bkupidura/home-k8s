{
  local s = $.k.storage.v1,
  cilium+: {
    policy+: {
      traefik+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'longhorn', app: 'longhorn-ui', 'io.kubernetes.pod.namespace': 'longhorn-system' } }], toPorts: [{ ports: [{ port: '80', protocol: 'TCP' }] }] },
        ],
      },
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { app: 'longhorn-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } }], toPorts: [{ ports: [{ port: '9500', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  falco+: {
    exception+:: {
      longhorn: {
        // longhorn-manager dups stdio into socket
        'longhorn-manager-redirect-stdout-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_stand_streams_redirect_activities',
            condition: 'or (container.image.repository=docker.io/longhornio/longhorn-manager and proc.cmdline="longhorn backup cleanup-all-mounts") or (container.image.repository=docker.io/longhornio/longhorn-manager and proc.name=longhorn-manage and proc.cmdline startswith "longhorn-manage -d daemon" and fd.rport in (8500, 8501, 8502, 8503))',
            override: {
              condition: 'append',
            },
          },
        ]),
        // longhorn-instance-manager health self-check `nc -zv localhost <port>`
        'incubating-longhorn-instance-manager-nc-network-tool-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_network_tool_activities',
            condition: 'or (container.image.repository=docker.io/longhornio/longhorn-instance-manager and proc.cmdline in ("nc -zv localhost 8500", "nc -zv localhost 8501", "nc -zv localhost 8502", "nc -zv localhost 8503"))',
            override: {
              condition: 'append',
            },
          },
          {
            macro: 'user_expected_system_procs_network_activity_conditions',
            condition: 'or (container.image.repository=docker.io/longhornio/longhorn-instance-manager and proc.cmdline="sh -c nc -zv localhost 8500 > /dev/null 2>&1 && nc -zv localhost 8501 > /dev/null 2>&1 && nc -zv localhost 8502 > /dev/null 2>&1 && nc -zv localhost 8503 > /dev/null 2>&1")',
            override: {
              condition: 'append',
            },
          },
        ]),
        // longhorn-instance-manager dups stdio into socket
        'longhorn-instance-manager-redirect-stdout-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_stand_streams_redirect_activities',
            condition: 'or (container.image.repository=docker.io/longhornio/longhorn-instance-manager and proc.cmdline startswith "longhorn-instan --debug daemon --listen :8500")',
            override: {
              condition: 'append',
            },
          },
        ]),
        // longhorn-manager and longhorn-instance-manager mount/net namespace
        'incubating-longhorn-manager-namespace-change-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_change_thread_namespace_activities',
            condition: 'or (container.image.repository=docker.io/longhornio/longhorn-manager and proc.name=longhorn-manage) or (container.image.repository=docker.io/longhornio/longhorn-manager and proc.name=nsenter and proc.pname=longhorn-manage) or (container.image.repository=docker.io/longhornio/longhorn-instance-manager and proc.name=longhorn and proc.pname="longhorn-instan") or (container.image.repository=docker.io/longhornio/longhorn-instance-manager and proc.name=nsenter and proc.pname=longhorn)',
            override: {
              condition: 'append',
            },
          },
        ]),
        // longhorn-csi-plugin run `mount --bind`
        'incubating-longhorn-csi-mount-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_mount_in_privileged_containers',
            condition: 'or (container.image.repository=docker.io/longhornio/longhorn-manager and container.name=longhorn-csi-plugin and proc.pname=longhorn-manage)',
            override: {
              condition: 'append',
            },
          },
        ]),
        'longhorn-trusted-k8s-api-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'k8s_containers',
            condition: 'or container.image.repository in (registry.k8s.io/sig-storage/csi-provisioner, docker.io/longhornio/csi-snapshotter, docker.io/longhornio/longhorn-manager, docker.io/longhornio/csi-provisioner, docker.io/longhornio/csi-resizer, docker.io/longhornio/csi-attacher)',
            override: {
              condition: 'append',
            },
          },
        ]),
      },
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'longhorn',
        rules: [
          {
            alert: 'LonghornWrongVolumeRobustness',
            expr: 'longhorn_volume_robustness{state=~"degraded|faulted"} == 1',
            'for': '10m',
            labels: { service: 'longhorn', severity: 'warning' },
            annotations: {
              summary: 'Volume {{ $labels.volume }} is not healthy',
            },
          },
          {
            alert: 'LonghornHighDiskUsage',
            expr: 'longhorn_disk_usage_bytes / longhorn_disk_capacity_bytes > 0.9',
            labels: { service: 'longhorn', severity: 'info' },
            annotations: {
              summary: 'High disk usage on {{ $labels.node }}',
            },
          },
          {
            alert: 'LonghornNodeDown',
            expr: 'longhorn_node_status{condition=~"(ready|schedulable|allowScheduling)"} != 1',
            labels: { service: 'longhorn', severity: 'critical' },
            annotations: {
              summary: 'Node {{ $labels.node }} is unhealthy ({{ $labels.condition }})',
            },
          },
          {
            alert: 'LonghornWrongDiskStatus',
            expr: 'longhorn_disk_status != 1',
            labels: { service: 'longhorn', severity: 'warning' },
            annotations: {
              summary: 'Disk {{ $labels.disk }} on {{ $labels.node }} is {{ $labels.condition }} ({{ $labels.condition_reason }})',
            },
          },
        ],
      },
    ],
  },
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('storage.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:admin',
          policy: 'two_factor',
        },
      },
    ],
  },
  storage+: {
    class_without_snapshot: s.storageClass.new('longhorn-standard')
                            + s.storageClass.withProvisioner('driver.longhorn.io')
                            + s.storageClass.withAllowVolumeExpansion(true)
                            + s.storageClass.withMountOptions(['noatime'])
                            + s.storageClass.withParameters({
                              numberOfReplicas: '3',
                              staleReplicaTimeout: '360',
                              fromBackup: '',
                            }),
    class_with_snapshot: s.storageClass.new('longhorn-standard-with-snapshots')
                         + s.storageClass.withProvisioner('driver.longhorn.io')
                         + s.storageClass.withAllowVolumeExpansion(true)
                         + s.storageClass.withMountOptions(['noatime'])
                         + s.storageClass.withParameters({
                           numberOfReplicas: '3',
                           staleReplicaTimeout: '360',
                           fromBackup: '',
                           recurringJobs: '[ { "name":"snap", "task":"snapshot", "cron":"15 */3 * * *", "retain": 8 } ]',
                         }),
    class_with_encryption: s.storageClass.new('longhorn-encrypted')
                           + s.storageClass.withProvisioner('driver.longhorn.io')
                           + s.storageClass.withAllowVolumeExpansion(true)
                           + s.storageClass.withMountOptions(['noatime'])
                           + s.storageClass.withParameters({
                             numberOfReplicas: '3',
                             staleReplicaTimeout: '360',
                             fromBackup: '',
                             recurringJobs: '[ { "name":"snap", "task":"snapshot", "cron":"15 */3 * * *", "retain": 8 } ]',
                             encrypted: 'true',
                             'csi.storage.k8s.io/provisioner-secret-name': 'longhorn-encryption-global',
                             'csi.storage.k8s.io/provisioner-secret-namespace': 'longhorn-system',
                             'csi.storage.k8s.io/node-publish-secret-name': 'longhorn-encryption-global',
                             'csi.storage.k8s.io/node-publish-secret-namespace': 'longhorn-system',
                             'csi.storage.k8s.io/node-stage-secret-name': 'longhorn-encryption-global',
                             'csi.storage.k8s.io/node-stage-secret-namespace': 'longhorn-system',
                           }),
  },
  longhorn: {
    namespace: $.k.core.v1.namespace.new('longhorn-system'),
    network_policy_manager: $._custom.cilium_network_policy.new(
      'longhorn-manager',
      'longhorn-system',
      { matchLabels: { app: 'longhorn-manager' } },
      ingress=[
        {
          fromEntities: ['host', 'remote-node'],
          toPorts: [
            { ports: [{ port: '9502', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { app: 'longhorn-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '9502', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9500', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { app: 'longhorn-csi-plugin', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '9500', protocol: 'TCP' }] },
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
          toEndpoints: [
            { matchLabels: { 'longhorn.io/component': 'instance-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8501', protocol: 'TCP' }, { port: '8503', protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { app: 'longhorn-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '9502', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    network_policy_instance_manager: $._custom.cilium_network_policy.new(
      'longhorn-instance-manager',
      'longhorn-system',
      { matchLabels: { 'longhorn.io/component': 'instance-manager' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { app: 'longhorn-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8501', protocol: 'TCP' }, { port: '8503', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'longhorn.io/component': 'instance-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '10000', endPort: 30000, protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[
        {
          toEndpoints: [
            { matchLabels: { 'longhorn.io/component': 'instance-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '10000', endPort: 30000, protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    network_policy_csi_plugin: $._custom.cilium_network_policy.new(
      'longhorn-csi-plugin',
      'longhorn-system',
      { matchLabels: { app: 'longhorn-csi-plugin' } },
      ingress=[],
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
          toEndpoints: [
            { matchLabels: { 'longhorn.io/component': 'instance-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '8501', protocol: 'TCP' }, { port: '10000', endPort: 30000, protocol: 'TCP' }] },
          ],
        },
        {
          toEndpoints: [
            { matchLabels: { app: 'longhorn-manager', 'io.kubernetes.pod.namespace': 'longhorn-system' } },
          ],
          toPorts: [
            { ports: [{ port: '9500', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    network_policy_csi_sidecars: {
      [sidecar]: $._custom.cilium_network_policy.new(
        sidecar,
        'longhorn-system',
        { matchLabels: { app: sidecar } },
        ingress=[],
        egress=[
          {
            toEntities: ['kube-apiserver'],
            toPorts: [
              { ports: [{ port: '6443', protocol: 'TCP' }] },
            ],
          },
        ],
      )
      for sidecar in ['csi-attacher', 'csi-provisioner', 'csi-resizer', 'csi-snapshotter']
    },
    secret_encryption: $.k.core.v1.secret.new('longhorn-encryption-global', {
                         CRYPTO_KEY_VALUE: std.base64(std.extVar('secrets').longhorn.encryption.global),
                         CRYPTO_KEY_PROVIDER: std.base64('secret'),
                       })
                       + $.k.core.v1.secret.metadata.withNamespace('longhorn-system'),
    helm: $._custom.helm.new('longhorn', 'longhorn', 'https://charts.longhorn.io', $._version.longhorn.chart, 'longhorn-system', {
      defaultSettings: {
        storageOverProvisioningPercentage: 100,
        nodeDownPodDeletionPolicy: 'delete-both-statefulset-and-deployment-pod',
        replicaAutoBalance: 'best-effort',
        concurrentAutomaticEngineUpgradePerNodeLimit: 1,
        orphanAutoDeletion: true,
        upgradeChecker: false,
      },
      annotations: {
        'prometheus.io/scrape': 'true',
        'prometheus.io/port': '9500',
      },
      networkPolicies: {
        restrictInternalTraffic: false,
      },
    }),
    ingress_route: $._custom.ingress_route.new('longhorn', 'longhorn-system', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`storage.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'longhorn-frontend', port: 80, namespace: 'longhorn-system' }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }, { name: 'x-forwarded-proto-https', namespace: 'traefik-system' }],
      },
    ], true),
  },
}
