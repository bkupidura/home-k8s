{
  kind: 'Dashboard',
  metadata: {
    name: 'falco',
    createdAt: '2026-10-11T07:26:36.187743863Z',
    updatedAt: '2026-10-11T07:26:40.597436269Z',
    version: 1,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'Falco',
    },
    panels: {
      '0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Number of events by priority',
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
                    query: 'sum by (priority_raw) (increase(falcosecurity_falcosidekick_falco_events_total[5m])) ',
                    seriesNameFormat: '{{ priority_raw }}',
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
            name: 'Top rules',
          },
          plugin: {
            kind: 'Table',
            spec: {
              columnSettings: [
                {
                  header: 'Rule',
                  name: 'rule',
                },
                {
                  enableSorting: false,
                  format: {
                    shortValues: true,
                    unit: 'decimal',
                  },
                  header: 'Events',
                  hide: false,
                  name: 'value',
                },
              ],
              defaultColumnHeight: 'auto',
              defaultColumnHidden: true,
              defaultColumnWidth: 'auto',
              density: 'compact',
              enableFiltering: false,
              pagination: false,
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'topk(10, sum by (rule) (increase(falcosecurity_falcosidekick_falco_events_total[$__range])))',
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
            name: 'Events by namespace / pod',
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
                    query: 'sum by (k8s_ns_name, k8s_pod_name) (increase(falcosecurity_falcosidekick_falco_events_total[5m])) ',
                    seriesNameFormat: '{{k8s_ns_name}}/{{ k8s_pod_name }}',
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
            name: 'Event drop rate',
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
                    query: 'rate(falcosecurity_scap_n_drops_total[5m])',
                    seriesNameFormat: '{{pod}}',
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
            name: 'Event drop rate by syscall',
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
                    query: 'sum by (drop) (rate(falcosecurity_scap_n_drops_buffer_total[5m]))',
                    seriesNameFormat: '{{ drop }} ',
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
            name: 'Output drop rate',
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
                    query: 'rate(falcosecurity_falco_outputs_queue_num_drops_total[5m])',
                    seriesNameFormat: '{{pod}}',
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
            name: 'FalcoSideKick delivery failures',
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
                    query: 'sum by (destination, status) (rate(falcosecurity_falcosidekick_outputs_total{status!="ok"}[5m]))',
                    seriesNameFormat: '{{destination}} - {{status}}',
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
            name: 'DS Logs',
          },
          plugin: {
            kind: 'LogsTable',
            spec: {
              allowWrap: false,
              enableDetails: true,
              showTime: false,
            },
          },
          queries: [
            {
              kind: 'LogQuery',
              spec: {
                plugin: {
                  kind: 'VictoriaLogsLogQuery',
                  spec: {
                    query: 'kubernetes__namespace_name:falco AND kubernetes__labels__app__kubernetes__io__name:falco AND kubernetes__container_name:falco',
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
            title: 'Falco metrics',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 15,
              content: {
                '$ref': '#/spec/panels/1',
              },
            },
            {
              x: 0,
              y: 8,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/2',
              },
            },
            {
              x: 0,
              y: 15,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/3',
              },
            },
            {
              x: 12,
              y: 15,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/4',
              },
            },
            {
              x: 0,
              y: 23,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/5',
              },
            },
            {
              x: 12,
              y: 23,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/6',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Falco logs',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 24,
              height: 14,
              content: {
                '$ref': '#/spec/panels/7',
              },
            },
          ],
        },
      },
    ],
    variables: [],
    annotations: [],
    duration: '3h',
    timezone: 'local',
    refreshInterval: '60s',
    links: [],
  },
}
