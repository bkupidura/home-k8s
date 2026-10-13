{
  kind: 'Dashboard',
  metadata: {
    name: 'k8s-pod',
    createdAt: '2026-10-10T18:48:44.701319122Z',
    updatedAt: '2026-10-10T18:48:44.701319122Z',
    version: 0,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'K8s - POD',
    },
    panels: {
      '0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of log messages',
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
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'k8s:all_logs:5m{kubernetes__pod_name="${pod}"}',
                    seriesNameFormat: 'all 5m',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'k8s:error_logs:5m{kubernetes__pod_name="${pod}"}',
                    seriesNameFormat: 'error 5m',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'k8s:warning_logs:5m{kubernetes__pod_name="${pod}"}',
                    seriesNameFormat: 'warning 5m',
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
            name: 'POD memory working set bytes',
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
              yAxis: {
                format: {
                  unit: 'bytes',
                },
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'container_memory_working_set_bytes{pod="${pod}", container=~"${container}"}',
                    seriesNameFormat: 'Usage {{pod}} - {{container}}',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'container_spec_memory_limit_bytes{pod="${pod}", container=~"${container}"}',
                    seriesNameFormat: 'Limit {{pod}} - {{container}}',
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
            name: 'POD memory usage bytes',
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
              yAxis: {
                format: {
                  unit: 'bytes',
                },
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'container_memory_usage_bytes{pod="${pod}", container=~"${container}"}',
                    seriesNameFormat: 'Usage {{pod}} - {{container}}',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'container_spec_memory_limit_bytes{pod="${pod}", container=~"${container}"}',
                    seriesNameFormat: 'Limit {{pod}} - {{container}}',
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
            name: 'CPU Usage seconds',
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
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_cpu_usage_seconds_total{pod="${pod}", container=~"${container}"}[5m])',
                    seriesNameFormat: '{{pod}} - {{container}}',
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
            name: 'POD CPU throtling',
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
              yAxis: {
                format: {
                  unit: 'percent-decimal',
                },
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'sum by(container, pod) (increase(container_cpu_cfs_throttled_periods_total{pod="${pod}",container=~"${container}"}[5m])) / sum by(container, pod) (increase(container_cpu_cfs_periods_total[5m])) ',
                    seriesNameFormat: '{{pod}} - {{container}}',
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
            name: 'POD Read / Write',
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
              yAxis: {
                format: {
                  unit: 'bytes',
                },
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_fs_reads_bytes_total{pod="${pod}", container=~"${container}"}[5m])',
                    seriesNameFormat: 'Read - {{ container }} - {{ device }}',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_fs_writes_bytes_total{pod="${pod}", container=~"${container}"}[5m]) ',
                    seriesNameFormat: 'Write - {{ container }} - {{ device }}',
                  },
                },
              },
            },
          ],
        },
      },
      '6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'POD Net pkts',
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
              yAxis: {
                format: {
                  unit: 'decimal',
                },
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_receive_packets_total{pod="${pod}"}[5m])',
                    seriesNameFormat: 'Receive',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_transmit_packets_total{pod="${pod}"}[5m]) ',
                    seriesNameFormat: 'Transmit',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_receive_errors_total{pod="${pod}"}[5m])',
                    seriesNameFormat: 'Receive - errors',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_transmit_errors_total{pod="${pod}"}[5m])',
                    seriesNameFormat: 'Transmit - errors',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_receive_packets_dropped_total{pod="${pod}"}[5m])',
                    seriesNameFormat: 'Receive - dropped',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_transmit_packets_dropped_total{pod="${pod}"}[5m])',
                    seriesNameFormat: 'Transmit - dropped',
                  },
                },
              },
            },
          ],
        },
      },
      '7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'POD Net bytes',
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
              yAxis: {
                format: {
                  unit: 'bytes',
                },
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_receive_bytes_total{pod="${pod}"}[5m])',
                    seriesNameFormat: 'Receive',
                  },
                },
              },
            },
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'increase(container_network_transmit_bytes_total{pod="${pod}"}[5m]) ',
                    seriesNameFormat: 'Transmit',
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
            title: 'POD stats',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0',
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
            title: 'Memory',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 24,
              height: 9,
              content: {
                '$ref': '#/spec/panels/1',
              },
            },
            {
              x: 0,
              y: 9,
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
            title: 'CPU',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/3',
              },
            },
            {
              x: 0,
              y: 8,
              width: 24,
              height: 7,
              content: {
                '$ref': '#/spec/panels/4',
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
            title: 'IO',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 24,
              height: 7,
              content: {
                '$ref': '#/spec/panels/5',
              },
            },
            {
              x: 0,
              y: 7,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/6',
              },
            },
            {
              x: 0,
              y: 15,
              width: 24,
              height: 7,
              content: {
                '$ref': '#/spec/panels/7',
              },
            },
          ],
          repeatVariable: '',
        },
      },
    ],
    variables: [
      {
        kind: 'ListVariable',
        spec: {
          name: 'pod',
          display: {
            hidden: false,
          },
          allowAllValue: false,
          allowMultiple: false,
          sort: 'none',
          plugin: {
            kind: 'PrometheusPromQLVariable',
            spec: {
              expr: 'container_memory_working_set_bytes',
              labelName: 'pod',
            },
          },
        },
      },
      {
        kind: 'ListVariable',
        spec: {
          name: 'container',
          display: {
            hidden: false,
          },
          allowAllValue: true,
          allowMultiple: false,
          customAllValue: '.+',
          sort: 'none',
          plugin: {
            kind: 'PrometheusPromQLVariable',
            spec: {
              expr: 'container_memory_working_set_bytes{pod="${pod}"}',
              labelName: 'container',
            },
          },
        },
      },
    ],
    annotations: [],
    duration: '1h',
    timezone: 'local',
    refreshInterval: '60s',
    datasources: {},
    links: [],
  },
}
