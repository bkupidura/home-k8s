{
  kind: 'Dashboard',
  metadata: {
    name: 'ups',
    createdAt: '2026-10-10T17:52:06.271630112Z',
    updatedAt: '2026-10-10T17:55:34.334439998Z',
    version: 2,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'UPS',
    },
    panels: {
      '0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Battery charge',
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
                  unit: 'percent',
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
                    query: 'network_ups_tools_battery_charge',
                    seriesNameFormat: '{{param_ups}}',
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
            name: 'Battery runtime',
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
                  unit: 'seconds',
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
                    query: 'network_ups_tools_battery_runtime',
                    seriesNameFormat: '{{param_ups}}',
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
            name: 'Input voltage',
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
                    query: 'network_ups_tools_input_voltage',
                    seriesNameFormat: 'Voltage - {{param_ups}}',
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
                    query: 'network_ups_tools_input_voltage_nominal',
                    seriesNameFormat: 'Nominal voltage - {{param_ups}}',
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
            name: 'Battery voltage',
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
                    query: 'network_ups_tools_battery_voltage',
                    seriesNameFormat: 'Voltage - {{param_ups}}',
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
                    query: 'network_ups_tools_battery_voltage_nominal',
                    seriesNameFormat: 'Nominant voltage - {{param_ups}}',
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
            name: 'UPS Status',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last',
              colorMode: 'value',
              metricLabel: 'flag}} - {{param_ups',
              thresholds: {
                steps: [],
              },
              legendMode: 'auto',
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
                    query: 'network_ups_tools_ups_status == 1',
                    seriesNameFormat: '{{ flag }} - {{ param_ups }}',
                  },
                },
              },
            },
          ],
          links: [],
        },
      },
      '5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'UPS Load',
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
                  unit: 'percent',
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
                    query: 'network_ups_tools_ups_load',
                    seriesNameFormat: '{{param_ups}}',
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
            title: 'Panel Group 1',
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
              height: 8,
              content: {
                '$ref': '#/spec/panels/1',
              },
            },
            {
              x: 0,
              y: 8,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/2',
              },
            },
            {
              x: 12,
              y: 8,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/3',
              },
            },
            {
              x: 0,
              y: 16,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/4',
              },
            },
            {
              x: 12,
              y: 16,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/5',
              },
            },
          ],
        },
      },
    ],
    variables: [],
    annotations: [],
    duration: '1h',
    timezone: 'local',
    refreshInterval: '60s',
    links: [],
  },
}
