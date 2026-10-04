{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'falco', 'io.kubernetes.pod.namespace': 'falco' } }], toPorts: [{ ports: [{ port: '8765', protocol: 'TCP' }] }] },
          { toEndpoints: [{ matchLabels: { 'app.kubernetes.io/name': 'falcosidekick', 'io.kubernetes.pod.namespace': 'falco' } }], toPorts: [{ ports: [{ port: '2801', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  logging+: {
    parsers+:: {
      falco: |||
        [PARSER]
            name falco
            format json
            time_key time
            time_format %Y-%m-%dT%H:%M:%S.%LZ
            time_keep On
      |||,
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'falco',
        rules: [
          {
            alert: 'FalcoEventPriorityCritical',
            expr: 'sum by (rule, priority_raw, hostname, k8s_ns_name, k8s_pod_name) (increase(falcosecurity_falcosidekick_falco_events_total{priority_raw=~"emergency|alert|critical|error"}[5m])) > 0',
            labels: { service: 'falco', severity: 'warning' },
            annotations: {
              summary: 'Falco "{{ $labels.rule }}" ({{ $labels.priority_raw }}) triggered on {{ $labels.hostname }} / {{ $labels.k8s_pod_name }}',
            },
          },
          {
            alert: 'FalcoEventPriorityError',
            expr: 'sum by (rule, priority_raw, hostname, k8s_ns_name, k8s_pod_name) (increase(falcosecurity_falcosidekick_falco_events_total{priority_raw=~"warning|notice"}[5m])) > 0',
            labels: { service: 'falco', severity: 'info' },
            annotations: {
              summary: 'Falco "{{ $labels.rule }}" ({{ $labels.priority_raw }}) triggered on {{ $labels.hostname }} / {{ $labels.k8s_pod_name }}',
            },
          },
          {
            alert: 'FalcoEventsRateHigh',
            expr: 'sum(rate(falcosecurity_falcosidekick_falco_events_total[5m])) > 5',
            'for': '2m',
            labels: { service: 'falco', severity: 'info' },
            annotations: {
              summary: 'High rate of Falco events ({{ $value | humanize }} per second)',
            },
          },
        ],
      },
    ],
  },
  falco+: {
    namespace: v1.namespace.new('falco'),
    exception+:: {
      k3s: {
        // k3s helmchart controller runs setuid
        'incubating-klipper-helm-setuid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_non_sudo_setuid_conditions',
            condition: 'or (container.image.repository=docker.io/rancher/klipper-helm and evt.arg.uid=klipper-helm)',
            override: {
              condition: 'append',
            },
          },
        ]),
        // k3s helm install writes to termination-log
        'incubating-klipper-helm-termination-log-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_create_files_below_dev_activities',
            condition: 'or (container.image.repository=docker.io/rancher/klipper-helm and fd.name=/dev/termination-log)',
            override: {
              condition: 'append',
            },
          },
        ]),
        // k3s sets sgid bit
        'incubating-k3s-token-rotation-setgid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_set_setuid_or_setgid_bit_conditions',
            condition: 'or (container.id=host and proc.name=k3s-server)',
            override: {
              condition: 'append',
            },
          },
        ]),
      },
      containerd: {
        'incubating-containerd-image-extract-setuid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_set_setuid_or_setgid_bit_conditions',
            condition: 'or (container.id=host and proc.name=containerd)',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-containerd-skel-bash-history-exception.yaml': std.manifestYamlDoc([
          {
            rule: 'Delete or rename shell history',
            condition: 'and not (proc.name=containerd and fd.name contains "/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/" and fd.name endswith "skel/.bash_history")',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-containerd-tmpmounts-shell-config-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_shell_config_modifiers',
            condition: 'or (container.id=host and proc.name=containerd and fd.name startswith "/var/lib/rancher/k3s/agent/containerd/tmpmounts/")',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-container-init-unshare-exception.yaml': std.manifestYamlDoc([
          {
            rule: 'Change namespace privileges via unshare',
            condition: 'and not (proc.name="runc:[0:PARENT]" and proc.cmdline="runc:[0:PARENT] init")',
            override: {
              condition: 'append',
            },
          },
        ]),
      },
      host: {
        'incubating-systemd-reexec-user-mgmt-exception.yaml': std.manifestYamlDoc([
          {
            rule: 'User mgmt binaries',
            condition: 'and not (proc.name=systemd and proc.cmdline startswith "systemd --system --deserialize=") and not (proc.name=adduser and proc.pname=rsyslog.postins)',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-rpcbind-rsyslogd-setuid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_non_sudo_setuid_conditions',
            condition: 'or (container.id=host and proc.pname=systemd and proc.name in (rpcbind, rsyslogd))',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-unattended-upgrades-setuid-chmod-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_set_setuid_or_setgid_bit_conditions',
            condition: 'or (container.id=host and proc.name=dpkg and proc.pname=unattended-upgr)',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-dhcpcd-self-setuid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'somebody_becoming_themselves',
            condition: 'or (user.name=dhcpcd and evt.arg.uid=dhcpcd)',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-openssh-client-postinst-setgid-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_set_setuid_or_setgid_bit_conditions',
            condition: 'or (container.id=host and proc.name=chmod and proc.pname="openssh-client." and proc.cmdline="chmod 2755 /usr/bin/ssh-agent")',
            override: {
              condition: 'append',
            },
          },
        ]),
        'incubating-systemd-tmpfiles-ssh-info-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_read_ssh_information_activities',
            condition: 'or (container.id=host and proc.name=systemd-tmpfile)',
            override: {
              condition: 'append',
            },
          },
        ]),
      },
      s6_overlay: {
        'incubating-s6-overlay-init-exception.yaml': std.manifestYamlDoc([
          {
            macro: 'user_known_set_setuid_or_setgid_bit_conditions',
            condition: 'or (proc.name=s6-supervise and proc.pname=s6-svscan and proc.cmdline startswith "s6-supervise " and evt.arg.filename endswith "/event") or (proc.name=s6-rc-init and proc.pname=rc.init and proc.cmdline="s6-rc-init -c /run/s6/db /run/service" and evt.arg.filename startswith "/run/s6-rc/servicedirs/" and evt.arg.filename endswith "/event")',
            override: {
              condition: 'append',
            },
          },
          {
            macro: 'user_known_non_sudo_setuid_conditions',
            condition: 'or (proc.name=s6-applyuidgid and proc.pname=s6-supervise and proc.cmdline startswith "s6-applyuidgid -Uz -- ")',
            override: {
              condition: 'append',
            },
          },
          {
            macro: 'user_known_cron_jobs',
            condition: 'or (proc.name=crontab and proc.pname=bash and proc.cmdline startswith "crontab -l -u ")',
            override: {
              condition: 'append',
            },
          },
          {
            macro: 'user_known_network_tool_activities',
            condition: 'or (proc.name=nc and proc.pname=s6-notifyonchec and proc.cmdline startswith "nc -z localhost ")',
            override: {
              condition: 'append',
            },
          },
        ]),
      },
      rules: {
        'incubating-unexpected-udp-traffic-disable.yaml': std.manifestYamlDoc([
          {
            rule: 'Unexpected UDP Traffic',
            enabled: false,
            override: {
              enabled: 'replace',
            },
          },
        ]),
        'incubating-bpf-not-profiled-disable.yaml': std.manifestYamlDoc([
          {
            rule: 'BPF Program Not Profiled',
            enabled: false,
            override: {
              enabled: 'replace',
            },
          },
        ]),
      },
    },
    network_policy: $._custom.cilium_network_policy.new(
      'falco',
      'falco',
      { matchLabels: { 'app.kubernetes.io/name': 'falco' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '8765', protocol: 'TCP' }] },
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
            { matchLabels: { 'app.kubernetes.io/name': 'falcosidekick', 'io.kubernetes.pod.namespace': 'falco' } },
          ],
          toPorts: [
            { ports: [{ port: '2801', protocol: 'TCP' }] },
          ],
        },
        {
          toCIDRSet: [
            { cidr: '0.0.0.0/0', except: $._config.cilium_network_local },
          ],
          toPorts: [
            { ports: [{ port: '443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    network_policy_falcosidekick: $._custom.cilium_network_policy.new(
      'falcosidekick',
      'falco',
      { matchLabels: { 'app.kubernetes.io/name': 'falcosidekick' } },
      ingress=[
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'falco', 'io.kubernetes.pod.namespace': 'falco' } },
          ],
          toPorts: [
            { ports: [{ port: '2801', protocol: 'TCP' }] },
          ],
        },
        {
          fromEndpoints: [
            { matchLabels: { 'app.kubernetes.io/name': 'victoria-metrics-single', 'io.kubernetes.pod.namespace': 'monitoring' } },
          ],
          toPorts: [
            { ports: [{ port: '2801', protocol: 'TCP' }] },
          ],
        },
      ],
      egress=[],
    ),
    helm: $._custom.helm.new('falco', 'falco', 'https://falcosecurity.github.io/charts', '9.1.0', 'falco', {
      falco: {
        rules_files: [
          '/etc/falco/falco_rules.yaml',
          '/etc/falco/falco-incubating_rules.yaml',
          '/etc/falco/falco_rules.local.yaml',
          '/etc/falco/rules.d',
        ],
        json_output: true,
        json_include_output_property: true,
        log_level: 'info',
        log_stderr: true,
      },
      falcoctl: {
        config: {
          artifact: {
            install: {
              refs: ['falco-rules:5', 'falco-incubating-rules:6'],
            },
            follow: {
              refs: ['falco-rules:5', 'falco-incubating-rules:6'],
            },
          },
        },
        artifact: {
          follow: {
            securityContext: {
              readOnlyRootFilesystem: true,
              capabilities: { drop: ['ALL'] },
            },
            mounts: {
              volumeMounts: [{ name: 'tmp', mountPath: '/tmp' }],
            },
          },
        },
      },
      containerSecurityContext: {
        readOnlyRootFilesystem: true,
        capabilities: {
          drop: ['ALL'],
          add: ['BPF', 'SYS_RESOURCE', 'PERFMON', 'SYS_PTRACE'],
        },
      },
      mounts: {
        volumes: [{ name: 'tmp', emptyDir: {} }],
      },
      driver: {
        enabled: true,
        kind: 'modern_ebpf',
        modernEbpf: {
          leastPrivileged: true,
          bufSizePreset: 6,
          cpusForEachBuffer: 4,
        },
      },
      metrics: {
        enabled: true,
        interval: '1h',
      },
      tolerations: [
        { effect: 'NoSchedule', key: 'node-role.kubernetes.io/master' },
        { effect: 'NoSchedule', key: 'node-role.kubernetes.io/control-plane' },
      ],
      podAnnotations: {
        'prometheus.io/scrape': 'true',
        'prometheus.io/port': '8765',
        'fluentbit.io/parser': 'falco',
      },
      resources: {
        requests: { memory: '100M', cpu: '100m' },
        limits: { memory: '250M', cpu: '200m' },
      },
      falcosidekick: {
        enabled: true,
        config: {
          customfields: 'source=falco',
        },
        webui: {
          enabled: false,
        },
        resources: {
          requests: { memory: '32M', cpu: '50m' },
          limits: { memory: '64M', cpu: '75m' },
        },
        replicaCount: 1,
        podAnnotations: {
          'prometheus.io/scrape': 'true',
          'prometheus.io/port': '2801',
        },
        securityContext: {
          readOnlyRootFilesystem: true,
          capabilities: { drop: ['ALL'] },
        },
      },
      customRules: std.foldl(
        function(acc, service) acc + $.falco.exception[service],
        std.objectFields($.falco.exception),
        {}
      ),
    }),
  },
}
