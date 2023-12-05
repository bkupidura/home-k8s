{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  logging+: {
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
  waf: {
    nginx_snippet:: |||
      server {
          listen 443 ssl http2;
          server_name %(server_name)s.%(domain)s;
          set $upstream https://%(upstream)s;
          ssl_certificate /ssl/tls.crt;
          ssl_certificate_key /ssl/tls.key;
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
            proxy_connect_timeout 5s;
            proxy_read_timeout 60s;
            proxy_redirect off;
            proxy_pass_header Authorization;
            proxy_pass $upstream;
          }
      }
    |||,
    nginx_config:: [
      $.waf.nginx_snippet % { server_name: server_name, domain: std.extVar('secrets').domain, upstream: $._config.vip.ingress, server_rules: std.join('\n', $._config.waf.server[server_name].rules) }
      for server_name in std.objectFields($._config.waf.server)
    ],
    service: s.new(
               'waf',
               { 'app.kubernetes.io/name': 'waf' },
               [v1.servicePort.withPort(443) + v1.servicePort.withProtocol('TCP') + v1.servicePort.withName('https')]
             )
             + s.metadata.withNamespace('home-infra')
             + s.metadata.withLabels({ 'app.kubernetes.io/name': 'waf' })
             + s.metadata.withAnnotations({ 'metallb.universe.tf/loadBalancerIPs': $._config.vip.waf })
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
                          ALLOWED_METHODS: 'GET HEAD POST OPTIONS DELETE PROPFIND CHECKOUT COPY DELETE LOCK MERGE MKACTIVITY MKCOL MOVE PROPPATCH PUT UNLOCK',
                        })
                        + c.resources.withRequests({ memory: '128Mi', cpu: '50m' })
                        + c.resources.withLimits({ memory: '128Mi', cpu: '50m' })
                        + c.livenessProbe.httpGet.withPath('/healthz')
                        + c.livenessProbe.httpGet.withPort('http')
                        + c.livenessProbe.withInitialDelaySeconds(30)
                        + c.livenessProbe.withPeriodSeconds(10)
                        + c.livenessProbe.withTimeoutSeconds(2),
                      ],
                      { 'app.kubernetes.io/name': 'waf' })
                + d.configVolumeMount('waf-config', '/nginx/conf.d', {})
                + d.secretVolumeMount(std.strReplace(std.extVar('secrets').domain, '.', '-') + '-tls', '/ssl', 256, {})
                + d.spec.strategy.withType('RollingUpdate')
                + d.metadata.withNamespace('home-infra')
                + d.spec.template.metadata.withAnnotations({ 'fluentbit.io/parser': 'waf' })
                + d.spec.template.spec.withTerminationGracePeriodSeconds(3),
  },
}
