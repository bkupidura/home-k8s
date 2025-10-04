{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  logging+: {
    rules+:: [
      {
        name: 'waf',
        interval: '1m',
        rules: [
          {
            record: 'waf:status_code:1m',
            expr: '_time:1m kubernetes__container_name: "waf" | stats by (parsed__code, parsed__host, parsed__method) count() as log_count',
          },
        ],
      },
    ],
    parsers+:: {
      waf: |||
        [PARSER]
            name waf
            format regex
            regex ^(?<remote_addr>[^ ]*)\/(?<http_x_forwarded_for>[^ ]*) - (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*) (?:"(?<request_filename>[^\"]*)" "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")
            time_key time
            time_format %d/%b/%Y:%H:%M:%S %z
      |||,
    },
  },
  monitoring+: {
    rules+:: [
      {
        name: 'waf',
        rules: [
          {
            alert: 'WAF5XXErrors',
            expr: 'sum by (parsed__host) (waf:status_code:1m{parsed__code=~"5..", parsed__host=~".*[a-z]+?"}) / sum by (parsed__host) (waf:status_code:1m) > 0.05',
            labels: { service: 'waf', severity: 'info' },
            annotations: {
              summary: '5XX error codes observed on WAF for {{ index $labels "parsed__host" }}',
            },
          },
          {
            alert: 'WAF4XXErrors',
            expr: 'sum by (parsed__host) (waf:status_code:1m{parsed__code=~"4(0[0-3]|0[5-9]|[1-9][0-9])", parsed__host=~".*[a-z]+?"}) / sum by (parsed__host) (waf:status_code:1m) > 0.1 and sum by (parsed__host) (waf:status_code:1m) > 50',
            labels: { service: 'waf', severity: 'info' },
            annotations: {
              summary: '4XX error codes observed on WAF for {{ index $labels "parsed__host" }}',
            },
          },
        ],
      },
    ],
  },
  waf: {
    nginx_snippet:: |||
      server {
          listen 443 ssl;
          http2 on;
          server_name %(domain)s;
          set $upstream https://%(upstream)s;
          ssl_certificate %(cert_dir)s/tls.crt;
          ssl_certificate_key %(cert_dir)s/tls.key;
          ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
          ssl_prefer_server_ciphers on;
          ssl_protocols TLSv1.3;
          ssl_verify_client off;
          modsecurity_rules '
            %(server_rules)s
          ';
          location / {
            client_max_body_size 0;
            proxy_set_header Host $host;
            proxy_set_header Proxy "";
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_http_version 1.1;
            proxy_buffering off;
            proxy_connect_timeout %(proxy_connect_timeout)s;
            proxy_read_timeout %(proxy_read_timeout)s;
            proxy_send_timeout %(proxy_send_timeout)s;
            proxy_redirect off;
            proxy_pass_header Authorization;
            proxy_pass $upstream;
          }
      }
    |||,
    nginx_config:: [
      $.waf.nginx_snippet % { domain: std.extVar('secrets').waf.server[server_name].domain, upstream: $._config.vip.ingress, server_rules: std.join('\n', std.extVar('secrets').waf.server[server_name].rules), proxy_connect_timeout: std.get(std.extVar('secrets').waf.server[server_name], 'proxy_connect_timeout', '5s'), proxy_read_timeout: std.get(std.extVar('secrets').waf.server[server_name], 'proxy_read_timeout', '30s'), proxy_send_timeout: std.get(std.extVar('secrets').waf.server[server_name], 'proxy_send_timeout', '30s'), cert_dir: std.extVar('secrets').waf.server[server_name].cert_dir }
      for server_name in std.objectFields(std.extVar('secrets').waf.server)
    ],
    certs:: [
      {
        secret: std.strReplace(std.split(std.extVar('secrets').waf.server[server_name].cert_dir, '/')[2], '.', '-') + '-tls',
        dir: std.extVar('secrets').waf.server[server_name].cert_dir,
      }
      for server_name in std.objectFields(std.extVar('secrets').waf.server)
    ],
    certs_sorted:: std.uniq(std.sort($.waf.certs, function(x) x.dir), function(x) x.dir),
    service: s.new(
               'waf',
               { 'app.kubernetes.io/name': 'waf' },
               [v1.servicePort.withPort(443) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('https')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'waf' })
             + s.metadata.withAnnotations({ 'metallb.io/loadBalancerIPs': $._config.vip.waf })
             + s.spec.withType('LoadBalancer')
             + s.spec.withExternalTrafficPolicy('Local')
             + s.spec.withPublishNotReadyAddresses(false),
    config: v1.configMap.new('waf-config', {
              'waf.conf': std.join('\n', $.waf.nginx_config),
            })
            + v1.configMap.metadata.withNamespace('home-infra'),
    deployment: d.new('waf',
                      1,
                      [
                        c.new('waf', $._version.waf.image)
                        + c.withImagePullPolicy('IfNotPresent')
                        + c.withPorts([v1.containerPort.newNamed(80, 'http'), v1.containerPort.newNamed(443, 'https')])
                        + c.withEnvMap({
                          TZ: $._config.tz,
                          PARANOIA: '4',
                          ANOMALY_INBOUND: '5',
                          ANOMALY_OUTBOUND: '4',
                          MODSEC_REQ_BODY_LIMIT: '20971520',
                          MODSEC_REQ_BODY_LIMIT_ACTION: 'ProcessPartial',
                          ALLOWED_METHODS: 'GET HEAD POST OPTIONS DELETE REPORT PROPFIND CHECKOUT COPY DELETE LOCK MERGE MKACTIVITY MKCOL MOVE PROPPATCH PUT UNLOCK',
                        })
                        + c.withVolumeMountsMixin([
                          v1.volumeMount.new(cert.secret, cert.dir)
                          for cert in $.waf.certs_sorted
                        ])
                        + c.resources.withRequests({ memory: '256Mi', cpu: '100m' })
                        + c.resources.withLimits({ memory: '256Mi', cpu: '100m' })
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.httpGet.withHttpHeaders([{ name: 'Host', value: 'localhost' }])
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'waf' })
                + d.configVolumeMount('waf-config', '/nginx/conf.d', {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.metadata.withAnnotations({ 'fluentbit.io/parser': 'waf' })
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3)
                + d.spec.template.spec.withVolumesMixin([
                  v1.volume.fromSecret(cert.secret, cert.secret)
                  for cert in $.waf.certs_sorted
                ]),
  },
}
