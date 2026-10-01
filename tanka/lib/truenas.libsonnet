{
  cilium+: {
    policy+: {
      'victoria-metrics-single'+: {
        egress+:: [
          { toCIDR: [std.format('%s/32', std.extVar('secrets').democratic_csi.http.host)], toPorts: [{ ports: [{ port: '9108', protocol: 'TCP' }] }] },
        ],
      },
    },
  },
  monitoring+: {
    extra_scrape+:: {
      truenas: {
        job_name: 'graphite-exporter-truenas',
        metrics_path: '/metrics',
        scheme: 'http',
        scrape_interval: '10s',
        static_configs: std.extVar('secrets').monitoring.truenas,
      },
    },
  },
}
