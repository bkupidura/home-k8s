{
  restic_check: {
    [std.format('restic_check_%s', repo_name)]: $._custom.cronjob.new(std.format('restic-check-%s', repo_name), 'home-infra', '15 18 * * *', [
                                                  $.k.core.v1.container.new('check', $._version.restic.image)
                                                  + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName(std.format('restic-secrets-%s', repo_name)))
                                                  + $.k.core.v1.container.withCommand([
                                                    '/bin/sh',
                                                    '-ec',
                                                    std.join('\n', [
                                                      std.format('restic --repo "%s" forget --keep-within 7d --keep-daily 21 --keep-weekly 24 --prune', std.extVar('secrets').restic.repo[repo_name].connection),
                                                      std.format('restic --repo "%s" check --read-data-subset 5%%', std.extVar('secrets').restic.repo[repo_name].connection),
                                                    ]),
                                                  ])
                                                  + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.core.v1.container.withVolumeMounts([
                                                    $.k.core.v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                  ]) else {},
                                                ])
                                                + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                  $.k.core.v1.volume.fromSecret('ssh', std.format('restic-ssh-%s', repo_name)) + $.k.core.v1.volume.secret.withDefaultMode(256),
                                                ]) else {}
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
  },
  restic_check_full: {
    [std.format('restic_check_full_%s', repo_name)]: $._custom.cronjob.new(std.format('restic-check-full-%s', repo_name), 'home-infra', '00 06 * * 6', [
                                                       $.k.core.v1.container.new('check', $._version.restic.image)
                                                       + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName(std.format('restic-secrets-%s', repo_name)))
                                                       + $.k.core.v1.container.withCommand([
                                                         '/bin/sh',
                                                         '-ec',
                                                         std.join('\n', [
                                                           std.format('restic --repo "%s" check --read-data', std.extVar('secrets').restic.repo[repo_name].connection),
                                                         ]),
                                                       ])
                                                       + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.core.v1.container.withVolumeMounts([
                                                         $.k.core.v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                       ]) else {},
                                                     ])
                                                     + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                       $.k.core.v1.volume.fromSecret('ssh', std.format('restic-ssh-%s', repo_name)) + $.k.core.v1.volume.secret.withDefaultMode(256),
                                                     ]) else {}
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
  },
  multus_dhcp_lan: {
    apiVersion: 'k8s.cni.cncf.io/v1',
    kind: 'NetworkAttachmentDefinition',
    metadata: {
      name: 'multus-dhcp-lan',
      namespace: 'smart-home',
    },
    spec: {
      config: '{\n            "name": "multus-dhcp-lan",\n            "plugins": [\n                {\n                    "type": "macvlan",\n                    "master": "net0",\n                    "ipam": {\n                        "type": "dhcp"\n                    }\n                }\n            ]\n        }',
    },
  },
  multus_dhcp_iot: {
    apiVersion: 'k8s.cni.cncf.io/v1',
    kind: 'NetworkAttachmentDefinition',
    metadata: {
      name: 'multus-dhcp-iot',
      namespace: 'smart-home',
    },
    spec: {
      config: '{\n            "name": "multus-dhcp-iot",\n            "plugins": [\n                {\n                    "type": "macvlan",\n                    "master": "vlan200",\n                    "ipam": {\n                        "type": "dhcp"\n                    }\n                }\n            ]\n        }',
    },
  },
}
