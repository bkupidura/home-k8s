{
  k: import 'github.com/jsonnet-libs/k8s-libsonnet/1.30/main.libsonnet',
  _custom:: {
    helm: {
      new(name, chart_name, repo, version, targetNamespace, values): {
        apiVersion: 'helm.cattle.io/v1',
        kind: 'HelmChart',
        metadata: {
          name: name,
          namespace: 'kube-system',
        },
        spec: {
          repo: repo,
          chart: chart_name,
          version: version,
          targetNamespace: targetNamespace,
          valuesContent: std.manifestYamlDoc(values, true),
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
      new(name, namespace, schedule, password_secret, ssh_secret, command, pvc): $._custom.cronjob.new(name + '-backup', namespace, schedule, [
                                                                                   $.k.core.v1.container.new('backup', $._version.restic.image)
                                                                                   + $.k.core.v1.container.withVolumeMounts([
                                                                                     $.k.core.v1.volumeMount.new('data', '/data', false),
                                                                                     if ssh_secret != null then $.k.core.v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                                                   ])
                                                                                   + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName(password_secret))
                                                                                   + $.k.core.v1.container.withCommand(command),
                                                                                 ])
                                                                                 + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname(name)
                                                                                 + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                                                   $.k.core.v1.volume.fromPersistentVolumeClaim('data', pvc),
                                                                                   if ssh_secret != null then $.k.core.v1.volume.fromSecret('ssh', ssh_secret) + $.k.core.v1.volume.secret.withDefaultMode(256),
                                                                                 ])
                                                                                 + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution(
                                                                                   $.k.core.v1.podAffinityTerm.withTopologyKey('kubernetes.io/hostname')
                                                                                   + $.k.core.v1.podAffinityTerm.labelSelector.withMatchExpressions(
                                                                                     { key: 'app.kubernetes.io/name', operator: 'In', values: [name] }
                                                                                   )
                                                                                 ),
    },
    cronjob_restore: {
      new(name, namespace, password_secret, ssh_secret, command, pvc): $._custom.cronjob.new(name + '-restore', namespace, '0 0 * * *', [
                                                                         $.k.core.v1.container.new('restore', $._version.restic.image)
                                                                         + $.k.core.v1.container.withVolumeMounts([
                                                                           $.k.core.v1.volumeMount.new('data', '/data', false),
                                                                           if ssh_secret != null then $.k.core.v1.volumeMount.new('ssh', '/root/.ssh', false),
                                                                         ])
                                                                         + $.k.core.v1.container.withEnvFrom($.k.core.v1.envFromSource.secretRef.withName(password_secret))
                                                                         + $.k.core.v1.container.withCommand(command),
                                                                       ])
                                                                       + $.k.batch.v1.cronJob.spec.withSuspend(true)
                                                                       + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withHostname(name)
                                                                       + $.k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withVolumes([
                                                                         $.k.core.v1.volume.fromPersistentVolumeClaim('data', pvc),
                                                                         if ssh_secret != null then $.k.core.v1.volume.fromSecret('ssh', ssh_secret) + $.k.core.v1.volume.secret.withDefaultMode(256),
                                                                       ]),
    },
    ingress_route: {
      new(name, namespace, entrypoints, routes, tls): {
        apiVersion: 'traefik.io/v1alpha1',
        kind: 'IngressRoute',
        metadata: {
          name: name,
          namespace: namespace,
        },
        spec: {
          entryPoints: entrypoints,
          routes: routes,
          [if tls != null then 'tls']: {
            secretName: tls,
          },

        },
      },
    },
    traefik_middleware: {
      new(name, spec): {
        apiVersion: 'traefik.io/v1alpha1',
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
