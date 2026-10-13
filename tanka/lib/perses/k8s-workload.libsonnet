{
  kind: 'Dashboard',
  metadata: {
    name: 'k8s-workload',
    createdAt: '2026-10-10T19:09:49.583140242Z',
    updatedAt: '2026-10-10T19:09:49.583140242Z',
    version: 0,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'K8s - Workload',
    },
    panels: {
      '0_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'HV Load',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'bottom',
                values: [
                  'min',
                  'max',
                  'mean',
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    minStep: '',
                    query: 'node_load1{node=~"${node}"}',
                    seriesNameFormat: '{{ node }}',
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
            name: 'POD memory usage per HV',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'bottom',
                values: [
                  'min',
                  'max',
                  'mean',
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
                    minStep: '',
                    query: 'sum by (kubernetes_io_hostname) (container_memory_usage_bytes{container!="", kubernetes_io_hostname=~"${node}"})',
                    seriesNameFormat: '{{ kubernetes_io_hostname }}',
                  },
                },
              },
            },
          ],
        },
      },
      '0_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'POD CPU usage per HV',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'bottom',
                values: [
                  'min',
                  'max',
                  'mean',
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
                    minStep: '',
                    query: 'sum by (kubernetes_io_hostname) (increase(container_cpu_usage_seconds_total{pod!="", container!="",kubernetes_io_hostname=~"${node}"}[10m])) ',
                    seriesNameFormat: '{{ kubernetes_io_hostname }}',
                  },
                },
              },
            },
          ],
        },
      },
      '0_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'POD CPU periods per HV',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'bottom',
                values: [
                  'min',
                  'max',
                  'mean',
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
                    minStep: '',
                    query: 'sum by(kubernetes_io_hostname) (increase(container_cpu_cfs_throttled_periods_total{container!="", kubernetes_io_hostname=~"${node}"}[5m]))',
                    seriesNameFormat: 'Throttled {{ kubernetes_io_hostname }}',
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
                    minStep: '',
                    query: 'sum by(kubernetes_io_hostname) (increase(container_cpu_cfs_periods_total{container!="", kubernetes_io_hostname=~"${node}"}[5m]))',
                    seriesNameFormat: 'Periods {{ kubernetes_io_hostname }}',
                  },
                },
              },
            },
          ],
        },
      },
      '0_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'POD memory limit per HV',
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
                    query: 'sum by (kubernetes_io_hostname) (container_spec_memory_limit_bytes{container!=""}) / on (kubernetes_io_hostname) label_replace(kube_node_status_allocatable{resource="memory"}, "kubernetes_io_hostname", "$1", "node", "(.+)")',
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
            name: 'Number of running PODs',
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
                    query: 'kubelet_running_pods{job="kubernetes-nodes"}',
                    seriesNameFormat: '{{kubernetes_io_hostname}}',
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
            name: 'Oversized POD | Memory',
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
                    minStep: '',
                    query: 'max by(pod, namespace) (max_over_time(container_memory_working_set_bytes{pod!=""}[1d]) / (128 * 1024 * 1024 <  container_spec_memory_limit_bytes < +Inf)) < 0.3',
                    seriesNameFormat: '{{ pod }}',
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
            name: 'Oversized POD | CPU',
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
                    minStep: '',
                    query: 'max by (pod, namespace) (max_over_time(k8s:container:cpu:throthling:5m[14d])) < 0.1',
                    seriesNameFormat: '{{ pod }}',
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
            title: 'Per node',
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
                '$ref': '#/spec/panels/0_0',
              },
            },
            {
              x: 0,
              y: 8,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_1',
              },
            },
            {
              x: 0,
              y: 16,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_2',
              },
            },
            {
              x: 0,
              y: 24,
              width: 24,
              height: 14,
              content: {
                '$ref': '#/spec/panels/0_3',
              },
            },
            {
              x: 0,
              y: 38,
              width: 24,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_4',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Global',
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
                '$ref': '#/spec/panels/1_0',
              },
            },
            {
              x: 0,
              y: 7,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_1',
              },
            },
            {
              x: 12,
              y: 7,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_2',
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
          name: 'node',
          display: {
            hidden: false,
          },
          defaultValue: '$__all',
          allowAllValue: true,
          allowMultiple: false,
          customAllValue: '.*',
          sort: 'none',
          plugin: {
            kind: 'PrometheusPromQLVariable',
            spec: {
              expr: 'node_load1',
              labelName: 'node',
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
