{
  k: import 'github.com/jsonnet-libs/k8s-libsonnet/1.24/main.libsonnet',
  _custom:: {
    helm: {
      new(name, repo, version, targetNamespace, values): {
        apiVersion: 'helm.cattle.io/v1',
        kind: 'HelmChart',
        metadata: {
          name: name,
          namespace: 'kube-system',
        },
        spec: {
          repo: repo,
          chart: name,
          version: version,
          targetNamespace: targetNamespace,
          valuesContent: std.manifestYamlDoc(values),
        },
      },
    },
    cronjob: {
      new(name, namespace, schedule, containers): $.k.batch.v1.cronJob.new(name, schedule, containers)
                                                  + $.k.batch.v1.cronJob.metadata.withNamespace(namespace)
                                                  + $.k.batch.v1.cronJob.spec.withSuccessfulJobsHistoryLimit(1)
                                                  + $.k.batch.v1.cronJob.spec.withConcurrencyPolicy('Forbid')
                                                  + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('OnFailure'),
    },
    cronjob_backup: {
      new(name, namespace, schedule, command, pvc): $._custom.cronjob.new(name + '-backup', namespace, schedule, [
                                                      $.k.core.v1.container.new('backup', $._version.restic.image)
                                                      + $.k.core.v1.container.withVolumeMounts([
                                                        $.k.core.v1.volumeMount.new('data', '/data', false),
                                                      ])
                                                      + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName('restic-secrets'))
                                                      + $.k.core.v1.container.withCommand(command),
                                                    ])
                                                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname(name)
                                                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([$.k.core.v1.volume.fromPersistentVolumeClaim('data', pvc)])
                                                    + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                                                      $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                                                      + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                                                        { key: 'app.kubernetes.io/name', operator: 'In', values: [name] }
                                                      )
                                                    ),
    },
    cronjob_restore: {
      new(name, namespace, command, pvc): $._custom.cronjob.new(name + '-restore', namespace, '0 0 * * *', [
                                            $.k.core.v1.container.new('restore', $._version.restic.image)
                                            + $.k.core.v1.container.withVolumeMounts([
                                              $.k.core.v1.volumeMount.new('data', '/data', false),
                                            ])
                                            + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName('restic-secrets'))
                                            + $.k.core.v1.container.withCommand(command),
                                          ])
                                          + $.k.batch.v1.cronJob.spec.withSuspend(true)
                                          + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname(name)
                                          + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([$.k.core.v1.volume.fromPersistentVolumeClaim('data', pvc)]),
    },
    ingress_route: {
      new(name, namespace, entrypoints, routes, tls=false): {
        apiVersion: 'traefik.containo.us/v1alpha1',
        kind: 'IngressRoute',
        metadata: {
          name: name,
          namespace: namespace,
        },
        spec: {
          entryPoints: entrypoints,
          routes: routes,
          [if tls then 'tls']: {
            secretName: std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls',
          },

        },
      },
    },
    traefik_middleware: {
      new(name, spec): {
        apiVersion: 'traefik.containo.us/v1alpha1',
        kind: 'Middleware',
        metadata: {
          name: name,
          namespace: 'traefik-system',
        },
        spec: spec,
      },
    },
  },
}
