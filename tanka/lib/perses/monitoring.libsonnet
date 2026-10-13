{
  kind: 'Dashboard',
  metadata: {
    name: 'monitoring',
    createdAt: '2026-10-09T19:32:35.165340976Z',
    updatedAt: '2026-10-09T19:32:35.265872406Z',
    version: 1,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'Monitoring',
    },
    panels: {
      '0': {
        kind: 'Panel',
        spec: {
          display: {
            name: '',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'value',
              sparkline: {},
              thresholds: {
                steps: [
                  {
                    color: '#73bf69',
                    value: 0,
                  },
                  {
                    color: '#f2495c',
                    value: 1,
                  },
                ],
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'sum(ALERTS{alertstate="firing", service!="dmh-watchdog"}) or 0',
                  },
                },
              },
            },
          ],
        },
      },
      '1': {
        kind: 'Panel',
        spec: {
          display: {
            name: '',
          },
          plugin: {
            kind: 'TimeSeriesTable',
            spec: {},
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'ALERTS{alertstate="firing", service!="dmh-watchdog"}',
                    seriesNameFormat: '{{alertgroup}} - {{alertname}} - {{service}} - {{severity}} - {{instance}} - {{ pod }}',
                  },
                },
              },
            },
          ],
        },
      },
      '2': {
        kind: 'Panel',
        spec: {
          display: {
            name: '',
          },
          plugin: {
            kind: 'StatusHistoryChart',
            spec: {},
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'sum by (alertname, severity) (ALERTS{alertstate="firing",service!="dmh-watchdog"})',
                    seriesNameFormat: '{{ alertname }} - {{ severity }}',
                  },
                },
              },
            },
          ],
        },
      },
      '3': {
        kind: 'Panel',
        spec: {
          display: {
            name: '',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'value',
              sparkline: {},
              thresholds: {
                steps: [
                  {
                    color: '#73bf69',
                    value: 0,
                  },
                  {
                    color: '#fade2a',
                    value: 1,
                  },
                ],
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'sum(ALERTS{alertstate="pending"}) or 0',
                  },
                },
              },
            },
          ],
        },
      },
      '4': {
        kind: 'Panel',
        spec: {
          display: {
            name: '',
          },
          plugin: {
            kind: 'TimeSeriesTable',
            spec: {},
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'ALERTS{alertstate="pending"}',
                    seriesNameFormat: '{{alertgroup}} - {{alertname}} - {{service}} - {{severity}} - {{instance}} - {{ pod }}',
                  },
                },
              },
            },
          ],
        },
      },
      '5': {
        kind: 'Panel',
        spec: {
          display: {
            name: '',
          },
          plugin: {
            kind: 'StatusHistoryChart',
            spec: {},
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'sum by (alertname, severity) (ALERTS{alertstate="pending"})',
                    seriesNameFormat: '{{ alertname }} - {{ severity }}',
                  },
                },
              },
            },
          ],
        },
      },
    },
    layouts: [
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Firing alerts',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 6,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0',
              },
            },
            {
              x: 6,
              y: 0,
              width: 18,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1',
              },
            },
            {
              x: 0,
              y: 8,
              width: 24,
              height: 9,
              content: {
                '$ref': '#/spec/panels/2',
              },
            },
          ],
          repeatVariable: '',
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Pending alerts',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 6,
              height: 8,
              content: {
                '$ref': '#/spec/panels/3',
              },
            },
            {
              x: 6,
              y: 0,
              width: 18,
              height: 8,
              content: {
                '$ref': '#/spec/panels/4',
              },
            },
            {
              x: 0,
              y: 8,
              width: 24,
              height: 9,
              content: {
                '$ref': '#/spec/panels/5',
              },
            },
          ],
          repeatVariable: '',
        },
      },
    ],
    variables: [],
    annotations: [],
    duration: '3h',
    refreshInterval: '30s',
    links: [
      {
        name: 'VM Alert',
        url: std.format('https://vm-alert.%s/vmalert/alerts', std.extVar('secrets').domain),
        targetBlank: true,
      },
      {
        name: 'VM Server',
        url: std.format('https://vm-server.%s/vmui/', std.extVar('secrets').domain),
        targetBlank: true,
      },
    ],
  },
}
