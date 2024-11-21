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
    rules+:: [
      {
        name: 'truenas',
        rules: [
          {
            alert: 'TruenasZFSPoolNotOnline',
            expr: 'zfs_pool{state!="online"} != 0',
            'for': '5m',
            labels: { service: 'truenas', severity: 'critical' },
            annotations: {
              summary: 'Truenas ZFS pool {{ $labels.pool }} is in {{ $labels.state }} on {{ $labels.name }}.',
            },
          },
        ],
      },
    ],
  },
}
