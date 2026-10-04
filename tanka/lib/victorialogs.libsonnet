{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'fluent-bit', 'io.kubernetes.pod.namespace': 'monitoring' } }], toPorts: [{ ports: [{ port: '2020', protocol: 'TCP' }] }] },
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'victoria-logs-single', 'io.kubernetes.pod.namespace': 'monitoring' } }], toPorts: [{ ports: [{ port: '9428', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  logging+: {
    rules+:: [
      {
        name: 'fluentbit',
        interval: '1m',
        rules: [
          {
            alert: 'FluentbitUnknownParser',
            expr: '_time:5m kubernetes__container_name: "fluent-bit" and contains_all("annotation parser", "not found") | stats count() as log_count | filter log_count :> 0',
            labels: { service: 'fluentbit', severity: 'warning' },
            annotations: {
              summary: 'Unknown fluentbit parser configured',
            },
          },
        ],
      },
    ],
  },
  falco+: {
    exception+:: {
      fluentbit: {
        'fluent-bit-trusted-k8s-api-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'k8s_containers',
            condition: std.format('or container.image.repository in (registry.%s/fluent-bit)', std.extVar('secrets').domain),
            override: {
              condition: 'append',
            },
          },
        ]),
      },
    },
  },
  fluentbit: {
    network_policy: $._custom.cilium_network_policy.new(
      'fluent-bit',
      'monitoring',
      { matchLabels: { 'app.kubernetes.io/name': 'fluent-bit' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '2020', protocol: 'TCP' }] },
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
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-logs-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    [if $.logging.parsers != null then 'parsers']:: [
      $.logging.parsers[parser]
      for parser in std.objectFields($.logging.parsers)
    ],
    helm: $._custom.helm.new('fluent-bit', 'fluent-bit', 'https://fluent.github.io/helm-charts', $._version.fluentbit.chart, 'monitoring', {
      config: {
        filters: |||
          [FILTER]
              name kubernetes
              match kube.*
              merge_log on
              merge_log_key parsed
              keep_log on
              annotations off
              k8s-logging.parser on
              k8s-logging.exclude on
          [FILTER]
              name nest
              match *
              operation lift
              nested_under parsed
              add_prefix parsed__
          [FILTER]
              name nest
              match kube.*
              operation lift
              nested_under kubernetes
              add_prefix kubernetes__
          [FILTER]
              name nest
              match kube.*
              operation lift
              nested_under kubernetes__labels
              add_prefix kubernetes__labels__
          [FILTER]
              name modify
              match kube.*
              rename kubernetes__labels__app.kubernetes.io/name kubernetes__labels__app__kubernetes__io__name
              rename kubernetes__labels__app.kubernetes.io/instance kubernetes__labels__app__kubernetes__io__instace
        |||,
        outputs: |||
          [OUTPUT]
              name http
              match *
              host victoria-logs-single-server.monitoring
              port 9428
              uri /insert/jsonline?_stream_fields=stream&_msg_field=log&_time_field=date&debug=0
              format json_lines
              json_date_format iso8601
              log_level warn
        |||,
        [if std.length($.fluentbit.parsers) > 0 then 'customParsers']: std.join('\n', $.fluentbit.parsers),
      },
      podAnnotations: {
        'prometheus.io/port': '2020',
        'prometheus.io/scrape': 'true',
        'prometheus.io/path': '/api/v1/metrics/prometheus',
      },
      securityContext: {
        allowPrivilegeEscalation: false,
        readOnlyRootFilesystem: true,
        capabilities: { drop: ['ALL'] },
      },
      resources: {
        limits: { memory: '128M', cpu: '50m' },
      },
      image: {
        repository: std.splitLimitR($._version.fluentbit.image, ':', 1)[0],
        tag: std.splitLimitR($._version.fluentbit.image, ':', 1)[1],
      },
    }),
  },
  victoria_logs: {
    network_policy_server: $._custom.cilium_network_policy.new(
      'victoria-logs-single',
      'monitoring',
      { matchLabels: { 'app.kubernetes.io/name': 'victoria-logs-single', 'app.kubernetes.io/instance': 'victoria-logs-single' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'fluent-bit', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-alert', 'app.kubernetes.io/instance': 'victoria-logs-alert', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'grafana', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[],
    ),
    rules_rendered:: [
      if std.get(group, 'enabled', true) then {
        name: group.name,
        [if std.get(group, 'interval') != null then 'interval']: group.interval,
        rules: group.rules,
      }
      for group in $.logging.rules
    ],
    pvc_server: p.new('victoria-logs')
                + p.metadata.withNamespace('monitoring')
                + p.spec.withAccessModes(['ReadWriteOnce'])
                + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
                + p.spec.resources.withRequests({ storage: '10Gi' }),
    helm_server: $._custom.helm.new('victoria-logs-single', 'victoria-logs-single', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.logs.chart, 'monitoring', {
      server: {
        image: {
          registry: $._version.victoria_metrics.logs.registry,
          repository: $._version.victoria_metrics.logs.repository,
          tag: $._version.victoria_metrics.logs.tag,
        },
        enabled: true,
        retentionPeriod: '4w',
        resources: {
          requests: { memory: '350M' },
          limits: { memory: '700M' },
        },
        persistentVolume: {
          enabled: true,
          existingClaim: 'victoria-logs',
        },
        podAnnotations: {
          'fluentbit.io/parser': 'victoria-json',
        },
        securityContext: {
          enabled: true,
          allowPrivilegeEscalation: false,
          readOnlyRootFilesystem: true,
          capabilities: { drop: ['ALL'] },
        },
      },
    }),
    network_policy_alert: $._custom.cilium_network_policy.new(
      'victoria-logs-alert',
      'monitoring',
      {
        matchLabels: {
          'app.kubernetes.io/name': 'victoria-metrics-alert',
          'app.kubernetes.io/instance': 'victoria-logs-alert',
        },
      },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '8880', protocol: 'TCP' }] },
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
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-logs-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9428', protocol: 'TCP' }] },
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
            { matchLabels: { 'app.kubernetes.io/name': 'alertmanager', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '9093', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    helm_alert: $._custom.helm.new('victoria-logs-alert', 'victoria-metrics-alert', 'https://victoriametrics.github.io/helm-charts/', $._version.victoria_metrics.alert.chart, 'monitoring', {
      server: {
        enabled: true,
        image: {
          registry: $._version.victoria_metrics.alert.registry,
          repository: $._version.victoria_metrics.alert.repository,
          tag: $._version.victoria_metrics.alert.tag,
        },
        resources: {
          requests: { memory: '25Mi' },
          limits: { memory: '50Mi' },
        },
        extraArgs: {
          configCheckInterval: '5m',
          'external.label': 'source=victoria-logs',
          'rule.defaultRuleType': 'vlogs',
        },
        datasource: {
          url: 'http://victoria-logs-single-server.monitoring:9428',
        },
        remote: {
          write: {
            url: 'http://victoria-metrics-single-server.monitoring:8428',
          },
          read: {
            url: 'http://victoria-metrics-single-server.monitoring:8428',
          },
        },
        notifier: {
          alertmanager: {
            url: 'http://alertmanager.monitoring:9093',
          },
        },
        config: {
          alerts: {
            groups: std.prune($.victoria_logs.rules_rendered),
          },
        },
        podAnnotations: {
          'fluentbit.io/parser': 'victoria-json',
        },
        securityContext: {
          enabled: true,
          allowPrivilegeEscalation: false,
          readOnlyRootFilesystem: true,
          capabilities: { drop: ['ALL'] },
        },
      },
    }),
  },
}
