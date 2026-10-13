{
  kind: 'Dashboard',
  metadata: {
    name: 'waf',
    createdAt: '2026-10-10T14:51:03.099769782Z',
    updatedAt: '2026-10-10T14:51:03.099769782Z',
    version: 0,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'WAF',
    },
    panels: {
      '0_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Blocked requests by reason',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'bottom',
                values: [
                  'last',
                  'max',
                ],
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: "kubernetes__container_name: \"waf\" \"ModSecurity:\" | extract '[msg \"<reason>\"]<_>client: <client>, server: <server>, request: \"<method> <url> HTTP' |\nstats by (reason) count() as log_count",
                  },
                },
              },
            },
          ],
        },
      },
      '0_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Blocked requests by client/server',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'bottom',
                values: [
                  'last',
                  'max',
                ],
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: "kubernetes__container_name: \"waf\" \"ModSecurity:\" | extract 'client: <client>, server: <server>, request: \"<method> <url> HTTP' | stats by (client, server) count() as log_count",
                  },
                },
              },
            },
          ],
        },
      },
      '1_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of 1XX requests',
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
                    value: 80,
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
                    query: 'sum(waf:status_code:1m{parsed__code=~"1.."})',
                  },
                },
              },
            },
          ],
        },
      },
      '1_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of 2XX requests',
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
                    value: 80,
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
                    query: 'sum(waf:status_code:1m{parsed__code=~"2.."})',
                  },
                },
              },
            },
          ],
        },
      },
      '1_10': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Avg 5XX requests',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'right',
                values: [
                  'last-number',
                  'max',
                ],
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
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
                    query: 'avg by (parsed__host) (waf:status_code:1m{parsed__host=~".*[a-z]+?",parsed__code=~"5.."})',
                    seriesNameFormat: '{{ parsed__host }}',
                  },
                },
              },
            },
          ],
        },
      },
      '1_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of 3XX requests',
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
                    value: 80,
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
                    query: 'sum(waf:status_code:1m{parsed__code=~"3.."})',
                  },
                },
              },
            },
          ],
        },
      },
      '1_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of 4XX requests',
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
                    value: 80,
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
                    query: 'sum(waf:status_code:1m{parsed__code=~"4.."})',
                  },
                },
              },
            },
          ],
        },
      },
      '1_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of 5XX requests',
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
                    value: 80,
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
                    query: 'sum(waf:status_code:1m{parsed__code=~"5.."})',
                  },
                },
              },
            },
          ],
        },
      },
      '1_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per host',
          },
          plugin: {
            kind: 'PieChart',
            spec: {
              calculation: 'last-number',
              legend: {
                position: 'bottom',
              },
              radius: 50,
              showLabels: false,
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'avg by (parsed__host) (waf:status_code:1m{parsed__host=~".*[a-z]+?"})',
                    seriesNameFormat: '{{ parsed__host }}',
                  },
                },
              },
            },
          ],
        },
      },
      '1_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per status code',
          },
          plugin: {
            kind: 'PieChart',
            spec: {
              calculation: 'last-number',
              legend: {
                mode: 'table',
                position: 'right',
              },
              radius: 50,
              showLabels: false,
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'avg by (parsed__code) (waf:status_code:1m{parsed__host=~".*[a-z]+?"})',
                    seriesNameFormat: '{{ parsed__code }}',
                  },
                },
              },
            },
          ],
        },
      },
      '1_7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Avg number of requests',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'right',
                values: [
                  'last-number',
                  'max',
                ],
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
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
                    query: 'avg by (parsed__host) (waf:status_code:1m{parsed__host=~".*[a-z]+?"})',
                    seriesNameFormat: '{{parsed__host}}',
                  },
                },
              },
            },
          ],
          links: [],
        },
      },
      '1_8': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Avg number of requests',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'right',
                values: [
                  'last-number',
                  'max',
                ],
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
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
                    query: 'avg by (parsed__code) (waf:status_code:1m{parsed__host=~".*[a-z]+?"})',
                    seriesNameFormat: '{{ parsed__code }}',
                  },
                },
              },
            },
          ],
        },
      },
      '1_9': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Avg 4XX requests',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'right',
                values: [
                  'last',
                  'max',
                ],
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
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
                    query: 'avg by (parsed__host) (waf:status_code:1m{parsed__host=~".*[a-z]+?",parsed__code=~"4.."})',
                    seriesNameFormat: '{{ parsed__host }}',
                  },
                },
              },
            },
          ],
        },
      },
      '2_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'WAF - blocked requests by reason ($host)',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: "kubernetes__container_name: \"waf\" \"ModSecurity:\" | extract '[msg \"<reason>\"]<_>client: <client>, server: <server>, request: \"<method> <url> HTTP' | server: \"$host\" | stats by (reason) count() as log_count",
                  },
                },
              },
            },
          ],
        },
      },
      '2_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per remote address 4XX/5XX ($host)',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: 'kubernetes__container_name: "waf" | parsed__host: $host | parsed__code:~"^(4|5)..$" | stats by (parsed__remote_addr, parsed__http_x_forwarded_for) count() as log_count',
                  },
                },
              },
            },
          ],
        },
      },
      '2_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per remote address ($host)',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: 'kubernetes__container_name: "waf" | parsed__host: $host | stats by (parsed__remote_addr, parsed__http_x_forwarded_for) count() as log_count',
                  },
                },
              },
            },
          ],
        },
      },
      '2_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per response code ($host)',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: 'kubernetes__container_name: "waf" | parsed__host: $host | stats by (parsed__code) count() as log_count',
                  },
                },
              },
            },
          ],
        },
      },
      '2_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per method ($host)',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: 'kubernetes__container_name: "waf" | parsed__host: $host | stats by (parsed__method) count() as log_count',
                  },
                },
              },
            },
          ],
        },
      },
      '2_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Requests per path ($host)',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsTimeSeriesQuery',
                  spec: {
                    query: 'kubernetes__container_name: "waf" | parsed__host: $host | stats by (parsed__path) count() as log_count',
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
            title: 'WAF',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 12,
              height: 9,
              content: {
                '$ref': '#/spec/panels/0_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 9,
              content: {
                '$ref': '#/spec/panels/0_1',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Requests',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 4,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_0',
              },
            },
            {
              x: 4,
              y: 0,
              width: 5,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_1',
              },
            },
            {
              x: 9,
              y: 0,
              width: 5,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_2',
              },
            },
            {
              x: 14,
              y: 0,
              width: 5,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_3',
              },
            },
            {
              x: 19,
              y: 0,
              width: 5,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_4',
              },
            },
            {
              x: 0,
              y: 7,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_5',
              },
            },
            {
              x: 12,
              y: 7,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_6',
              },
            },
            {
              x: 0,
              y: 15,
              width: 24,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_7',
              },
            },
            {
              x: 0,
              y: 22,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_8',
              },
            },
            {
              x: 0,
              y: 30,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_9',
              },
            },
            {
              x: 12,
              y: 30,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_10',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Per host',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2_1',
              },
            },
            {
              x: 0,
              y: 7,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2_2',
              },
            },
            {
              x: 12,
              y: 7,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2_3',
              },
            },
            {
              x: 0,
              y: 14,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2_4',
              },
            },
            {
              x: 12,
              y: 14,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2_5',
              },
            },
          ],
        },
      },
    ],
    variables: [
      {
        kind: 'ListVariable',
        spec: {
          display: {
            name: 'host',
            hidden: false,
          },
          allowAllValue: false,
          allowMultiple: false,
          sort: 'alphabetical-desc',
          plugin: {
            kind: 'PrometheusPromQLVariable',
            spec: {
              expr: 'count by (parsed__host) (count_over_time(waf:status_code:1m[$__range]))',
              labelName: 'parsed__host',
            },
          },
          name: 'host',
        },
      },
    ],
    annotations: [],
    duration: '6h',
    timezone: 'local',
    refreshInterval: '60s',
    datasources: {},
    links: [],
  },
}
