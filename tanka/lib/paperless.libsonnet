{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local p = v1.persistentVolumeClaim,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  authelia+: {
    access_control+:: [
      {
        order: 1,
        rule: {
          domain: [
            std.format('paperless.%s', std.extVar('secrets').domain),
          ],
          subject: 'group:docs',
          policy: 'two_factor',
        },
      },
    ],
  },
  paperless: {
    update:: $._config.update,
    restore:: $._config.restore,
    pvc: p.new('paperless')
         + p.metadata.withNamespace('self-hosted')
         + p.spec.withAccessModes(['ReadWriteOnce'])
         + p.spec.withStorageClassName(std.get($.storage.class_with_encryption.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '2Gi' }),
    service: s.new('paperless', { 'app.kubernetes.io/name': 'paperless' }, [v1.servicePort.withPort(8000) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('http')])
             + s.metadata.withNamespace('self-hosted')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'paperless' }),
    ingress_route: $._custom.ingress_route.new('paperless', 'self-hosted', ['websecure'], [
      {
        kind: 'Rule',
        match: std.format('Host(`paperless.%s`)', std.extVar('secrets').domain),
        services: [{ name: 'paperless', port: 8000 }],
        middlewares: [{ name: 'lan-whitelist', namespace: 'traefik-system' }, { name: 'auth-authelia', namespace: 'traefik-system' }],
      },
    ], std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls'),
    cronjob_backup: $._custom.cronjob_backup.new('paperless', 'self-hosted', '30 05,17 * * *', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose backup .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'paperless'),
    cronjob_restore: $._custom.cronjob_restore.new('paperless', 'self-hosted', 'restic-secrets-default', 'restic-ssh-default', ['/bin/sh', '-ec', std.join(
      '\n',
      ['cd /data', std.format('restic --repo "%s" --verbose restore latest --target .', std.extVar('secrets').restic.repo.default.connection)]
    )], 'paperless'),
    deployment: d.new('paperless',
                      if $.paperless.restore then 0 else 1,
                      [
                        c.new('paperless', $._version.paperless.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([
                          v1.containerPort.newNamed(8000, 'http'),
                        ])
                        + c.withEnvMap({
                          PAPERLESS_DBENGINE: 'mariadb',
                          PAPERLESS_DBHOST: 'mariadb.home-infra',
                          PAPERLESS_DBPORT: '3306',
                          PAPERLESS_DBNAME: 'paperless',
                          PAPERLESS_DBUSER: 'paperless',
                          PAPERLESS_DBPASS: std.extVar('secrets').paperless.db.password,
                          PAPERLESS_URL: std.format('https://paperless.%s', std.extVar('secrets').domain),
                          PAPERLESS_OCR_LANGUAGE: 'pol+eng',
                          PAPERLESS_OCR_LANGUAGES: 'pol',
                          PAPERLESS_FILENAME_FORMAT: '{{ document_type }}/{{ created_year }}/{{ created_month }}/{{ title }}',
                          PAPERLESS_CONSUMPTION_DIR: '/data/consume',
                          PAPERLESS_DATA_DIR: '/data/data',
                          PAPERLESS_EMPTY_TRASH_DIR: '/data/trash',
                          PAPERLESS_MEDIA_ROOT: '/data/media',
                          PAPERLESS_REDIS: std.extVar('secrets').paperless.redis_url,
                          PAPERLESS_REDIS_PREFIX: 'paperless',
                          PAPERLESS_SECRET_KEY: std.extVar('secrets').paperless.secret_key,
                          PAPERLESS_ENABLE_HTTP_REMOTE_USER: 'true',
                          PAPERLESS_ENABLE_HTTP_REMOTE_USER_API: 'true',
                          PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME: 'HTTP_REMOTE_USER',
                          PAPERLESS_LOGOUT_REDIRECT_URL: std.format('https://auth.%s', std.extVar('secrets').domain),
                          PAPERLESS_USE_X_FORWARD_HOST: 'True',
                          PAPERLESS_OCR_USER_ARGS: '{"invalidate_digital_signatures": true}',
                          PAPERLESS_TASK_WORKERS: '1',
                          PAPERLESS_THREADS_PER_WORKER: '1',
                          PAPERLESS_EMAIL_TASK_CRON: 'disable',
                        })
                        + c.resources.withRequests({ memory: '1024Mi', cpu: '300m' })
                        + c.resources.withLimits({ memory: '1500Mi', cpu: '500m' })
                        + (if $.paperless.update == false then
                             c.readinessProbe.tcpSocket.withPort('http')
                             + c.readinessProbe.withInitialDelaySeconds(10)
                             + c.readinessProbe.withPeriodSeconds(10)
                             + c.readinessProbe.withTimeoutSeconds(1)
                             + c.livenessProbe.httpGet.withPath('/')
                             + c.livenessProbe.httpGet.withPort('http')
                             + c.livenessProbe.withInitialDelaySeconds(90)
                             + c.livenessProbe.withPeriodSeconds(10)
                             + c.livenessProbe.withTimeoutSeconds(3)
                           else {}),
                      ],
                      { 'app.kubernetes.io/name': 'paperless' })
                + d.pvcVolumeMount('paperless', '/data', false, {})
                + d.spec.strategy.withType('Recreate')
                + d.metadata.withNamespace('self-hosted')
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.spec.withEnableServiceLinks(false),
  },
}
