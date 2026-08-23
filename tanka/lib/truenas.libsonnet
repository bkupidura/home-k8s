{
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
