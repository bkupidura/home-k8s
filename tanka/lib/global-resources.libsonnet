{
  local v1 = $.k.core.v1,
  local c = v1.container,
  restic_check: {
    [std.format('restic_check_%s', repo_name)]: $._custom.cronjob.new(std.format('restic-check-%s', repo_name), 'home-infra', '15 17 * * *', [
                                                  c.new('check', $._version.restic.image)
                                                  + c.withEnvFrom(v1.envFromSource.secretRef.withName(std.format('restic-secrets-%s', repo_name)))
                                                  + c.withCommand([
                                                    '/bin/sh',
                                                    '-ec',
                                                    std.join('\n', [
                                                      'restic forget --keep-within 7d --keep-daily 30 --keep-weekly 24 --keep-monthly 12 --prune',
                                                      'restic check --read-data-subset 10%',
                                                    ]),
                                                  ])
                                                  + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then c.withVolumeMounts([
                                                    v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                  ]) else {},
                                                ])
                                                + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                  v1.volume.fromSecret('ssh', std.format('restic-ssh-%s', repo_name)) + v1.volume.secret.withDefaultMode(256),
                                                ]) else {}
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
  },
  restic_check_full: {
    [std.format('restic_check_full_%s', repo_name)]: $._custom.cronjob.new(std.format('restic-check-full-%s', repo_name), 'home-infra', '30 06 * * 6', [
                                                       c.new('check', $._version.restic.image)
                                                       + c.withEnvFrom(v1.envFromSource.secretRef.withName(std.format('restic-secrets-%s', repo_name)))
                                                       + c.withCommand([
                                                         '/bin/sh',
                                                         '-ec',
                                                         std.join('\n', [
                                                           'restic check --read-data',
                                                         ]),
                                                       ])
                                                       + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then c.withVolumeMounts([
                                                         v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                       ]) else {},
                                                     ])
                                                     + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                       v1.volume.fromSecret('ssh', std.format('restic-ssh-%s', repo_name)) + v1.volume.secret.withDefaultMode(256),
                                                     ]) else {}
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
  },
  restic_unlock: {
    [std.format('restic_unlock_%s', repo_name)]: $._custom.cronjob.new(std.format('restic-unlock-%s', repo_name), 'home-infra', '10 */2 * * *', [
                                                   c.new('unlock', $._version.restic.image)
                                                   + c.withEnvFrom(v1.envFromSource.secretRef.withName(std.format('restic-secrets-%s', repo_name)))
                                                   + c.withCommand([
                                                     '/bin/sh',
                                                     '-ec',
                                                     std.join('\n', [
                                                       'restic unlock',
                                                     ]),
                                                   ])
                                                   + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then c.withVolumeMounts([
                                                     v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                   ]) else {},
                                                 ])
                                                 + if std.get(std.extVar('secrets').restic.repo[repo_name], 'ssh_key', false) != false then $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                   v1.volume.fromSecret('ssh', std.format('restic-ssh-%s', repo_name)) + v1.volume.secret.withDefaultMode(256),
                                                 ]) else {}
    for repo_name in std.objectFields(std.extVar('secrets').restic.repo)
  },
  restic_canary: {
    config: v1.configMap.new('restic-canary', {
              'canary.conf': std.join('\n', std.flatMap(
                function(host) std.map(
                  function(f) if std.get(f, 'hash', '') != '' then std.format('%s %s %s', [host, f.filename, f.hash]) else std.format('%s %s', [host, f.filename]),
                  std.extVar('secrets').restic.canary[host],
                ),
                std.objectFields(std.extVar('secrets').restic.canary),
              )),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    canary: $._custom.cronjob.new('restic-canary', 'home-infra', '0 18 * * *', [
              c.new('canary', $._version.restic.image)
              + c.withEnvFrom(v1.envFromSource.secretRef.withName('restic-secrets-default'))
              + c.withCommand(['/bin/sh', '-ec', |||
                CONFIG=/canary/canary.conf
                RESTORE_BASE=/tmp/r
                FAILED=0
                for HOST in $(awk '{print $1}' "${CONFIG}" | sort -u); do
                  echo "Checking: ${HOST}"
                  TARGET="${RESTORE_BASE}/${HOST}"
                  INCLUDES=$(awk -v h="${HOST}" '$1==h {printf "--include %s ", $2}' "${CONFIG}")
                  mkdir -p "${TARGET}"
                  if restic restore --no-lock latest -H "${HOST}" ${INCLUDES} --target "${TARGET}" 2>&1; then
                    while IFS= read -r LINE; do
                      set -- ${LINE}
                      FILE=$2; HASH=$3
                      if [ -n "${HASH}" ]; then
                        if ! echo "${HASH}  ${TARGET}${FILE}" | sha256sum -c - 2>&1; then
                          echo "HASH MISMATCH: ${HOST} ${FILE}"
                          FAILED=1
                        fi
                      else
                        if [ ! -f "${TARGET}${FILE}" ]; then
                          echo "FILE MISSING: ${HOST} ${FILE}"
                          FAILED=1
                        fi
                      fi
                    done < <(awk -v h="${HOST}" '$1==h' "${CONFIG}")
                  else
                    echo "RESTORE FAILED: ${HOST}"
                    FAILED=1
                  fi
                  rm -rf "${TARGET}"
                done
                exit ${FAILED}
              |||])
              + c.withVolumeMounts(
                [v1.volumeMount.new('restic-canary', '/canary', false)]
                + if std.get(std.extVar('secrets').restic.repo.default, 'ssh_key', false) != false then [v1.volumeMount.new('ssh', '/root/.ssh', false)] else []
              ),
            ])
            + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes(
              [v1.volume.fromConfigMap('restic-canary', 'restic-canary')]
              + if std.get(std.extVar('secrets').restic.repo.default, 'ssh_key', false) != false then [v1.volume.fromSecret('ssh', 'restic-ssh-default') + v1.volume.secret.withDefaultMode(256)] else []
            ),
  },
  multus_dhcp_lan: {
    apiVersion: 'k8s.cni.cncf.io/v1',
    kind: 'NetworkAttachmentDefinition',
    metadata: {
      name: 'multus-dhcp-lan',
      namespace: 'kube-system',
    },
    spec: {
      config: '{\n            "name": "multus-dhcp-lan",\n            "plugins": [\n                {\n                    "type": "macvlan",\n                    "master": "vlan100",\n                    "ipam": {\n                        "type": "dhcp"\n                    }\n                }\n            ]\n        }',
    },
  },
  multus_dhcp_iot: {
    apiVersion: 'k8s.cni.cncf.io/v1',
    kind: 'NetworkAttachmentDefinition',
    metadata: {
      name: 'multus-dhcp-iot',
      namespace: 'kube-system',
    },
    spec: {
      config: '{\n            "name": "multus-dhcp-iot",\n            "plugins": [\n                {\n                    "type": "macvlan",\n                    "master": "vlan200",\n                    "ipam": {\n                        "type": "dhcp"\n                    }\n                }\n            ]\n        }',
    },
  },
}
