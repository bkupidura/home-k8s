{
  kind: 'Dashboard',
  metadata: {
    name: 'truenas',
    createdAt: '2026-10-11T07:54:49.580346807Z',
    updatedAt: '2026-10-11T08:26:19.483672843Z',
    version: 5,
    tags: [
      'truenas',
    ],
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'TrueNAS',
    },
    panels: {
      '0_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'System load',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
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
                    query: 'truenas_load{instance=~"$instance"}',
                    seriesNameFormat: '{{ window }}',
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
            name: 'CPU temperature',
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
                    query: 'truenas_cpu_temperature_celsius{instance=~"$instance"}',
                    seriesNameFormat: '{{core}}',
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
            name: 'Memory usage',
          },
          plugin: {
            kind: 'PieChart',
            spec: {
              calculation: 'last-number',
              format: {
                decimalPlaces: 1,
                shortValues: true,
                unit: 'bytes',
              },
              radius: 50,
              showLabels: true,
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
                    query: 'truenas_meminfo_available_bytes{instance="$instance"}',
                    seriesNameFormat: 'Available',
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
                    query: 'truenas_meminfo_total_bytes{instance="$instance"}',
                    seriesNameFormat: 'Total',
                  },
                },
              },
            },
          ],
        },
      },
      '0_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Processes',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 1,
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
                    query: 'truenas_active_processes{instance=~"$instance"}',
                    seriesNameFormat: '{{kind}}',
                  },
                },
              },
            },
          ],
        },
      },
      '10_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk I/O - $disk',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              legend: {
                position: 'bottom',
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
                    query: 'truenas_disk_read_ops{instance=~"$instance", disk=~"$disk"}',
                    seriesNameFormat: 'Read',
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
                    query: 'truenas_disk_write_ops{instance=~"$instance", disk=~"$disk"}',
                    seriesNameFormat: 'Write',
                  },
                },
              },
            },
          ],
        },
      },
      '10_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk bandwith - $disk',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                format: {
                  unit: 'bytes/sec',
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
                    query: 'truenas_disk_reads{instance=~"$instance", disk=~"$disk"}',
                    seriesNameFormat: 'Read',
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
                    query: 'truenas_disk_writes{instance=~"$instance", disk=~"$disk"}',
                    seriesNameFormat: 'Write',
                  },
                },
              },
            },
          ],
        },
      },
      '10_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk busy - $disk',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                format: {
                  unit: 'milliseconds',
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
                    query: 'truenas_disk_busy_ms{instance=~"$instance", disk=~"$disk"}',
                    seriesNameFormat: '',
                  },
                },
              },
            },
          ],
        },
      },
      '10d8b6ed867e49509adf618261dcb3fe': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'CPU Usage',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                position: 'bottom',
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
                    query: 'truenas_cpu_usage{instance="$instance"}',
                    seriesNameFormat: '{{ cpu }}',
                  },
                },
              },
            },
          ],
        },
      },
      '15194cfd60964e0c92346ca7d32cf306': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Bytes',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                show: true,
                label: '',
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
                    query: 'truenas_net_sent_bytes{instance=~"$instance"}',
                    seriesNameFormat: '{{ interface }} - Sent',
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
                    query: 'truenas_net_received_bytes{instance=~"$instance"}',
                    seriesNameFormat: '{{ interface }} - Recv',
                  },
                },
              },
            },
          ],
        },
      },
      '3_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Pakets',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
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
                    query: 'truenas_net_packets_sent{instance=~"$instance"}',
                    seriesNameFormat: '{{ interface }} - Sent',
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
                    query: 'truenas_net_packets_received{instance=~"$instance"}',
                    seriesNameFormat: '{{ interface }} - Recv',
                  },
                },
              },
            },
          ],
        },
      },
      '7_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS I/O',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
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
                    query: 'truenas_nfsd_io{instance=~"$instance"}',
                    seriesNameFormat: '{{op}}',
                  },
                },
              },
            },
          ],
        },
      },
      '7_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS net I/O',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                format: {
                  unit: 'packets/sec',
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
                    query: 'truenas_nfsd_net{instance=~"$instance"}',
                    seriesNameFormat: '{{op}}',
                  },
                },
              },
            },
          ],
        },
      },
      '7_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS threads',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
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
                    query: 'truenas_nfsd_threads{instance=~"$instance"}',
                    seriesNameFormat: 'threads',
                  },
                },
              },
            },
          ],
        },
      },
      '7_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS readcache',
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
                  unit: 'reads/sec',
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
                    query: 'truenas_nfsd_readcache{instance=~"$instance"}',
                    seriesNameFormat: '{{op}}',
                  },
                },
              },
            },
          ],
        },
      },
      '7_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS RPC',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                format: {
                  unit: 'ops/sec',
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
                    query: 'truenas_nfsd_rpc{instance=~"$instance"}',
                    seriesNameFormat: '{{op}}',
                  },
                },
              },
            },
          ],
        },
      },
      '7_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS proc4',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                format: {
                  unit: 'ops/sec',
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
                    query: 'truenas_nfsd_proc4{instance=~"$instance"}',
                    seriesNameFormat: '{{op}}',
                  },
                },
              },
            },
          ],
        },
      },
      '7_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NFS proc4ops',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'list',
                position: 'bottom',
              },
              visual: {
                areaOpacity: 0.1,
                connectNulls: false,
                display: 'line',
                lineWidth: 1,
              },
              yAxis: {
                format: {
                  unit: 'ops/sec',
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
                    query: 'truenas_nfsd_proc4ops{instance=~"$instance"}',
                    seriesNameFormat: '{{op}}',
                  },
                },
              },
            },
          ],
        },
      },
      '9_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk temperature',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                mode: 'table',
                position: 'right',
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
                    query: 'truenas_disk_temperature_celsius',
                    seriesNameFormat: '{{ disk }}',
                  },
                },
              },
            },
          ],
        },
      },
      '1f0977234cd04118a51c952b85f8f469': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Drops',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {
              legend: {
                position: 'bottom',
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
                    query: 'truenas_net_drops_inbound',
                    seriesNameFormat: '{{ interface }} - Inbound',
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
                    query: 'truenas_net_drops_outbound',
                    seriesNameFormat: '{{ interface }} - Outbound',
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
            title: 'General',
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
              x: 0,
              y: 9,
              width: 12,
              height: 9,
              content: {
                '$ref': '#/spec/panels/0_2',
              },
            },
            {
              x: 12,
              y: 9,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/0_3',
              },
            },
            {
              x: 18,
              y: 9,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/0_5',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 9,
              content: {
                '$ref': '#/spec/panels/10d8b6ed867e49509adf618261dcb3fe',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Network',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/15194cfd60964e0c92346ca7d32cf306',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/1f0977234cd04118a51c952b85f8f469',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'NFS',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_0',
              },
            },
            {
              x: 6,
              y: 0,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_1',
              },
            },
            {
              x: 12,
              y: 0,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_2',
              },
            },
            {
              x: 18,
              y: 0,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_3',
              },
            },
            {
              x: 0,
              y: 9,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_4',
              },
            },
            {
              x: 6,
              y: 9,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_5',
              },
            },
            {
              x: 12,
              y: 9,
              width: 6,
              height: 9,
              content: {
                '$ref': '#/spec/panels/7_6',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Disk global',
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
                '$ref': '#/spec/panels/9_0',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Disk - $disk',
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
                '$ref': '#/spec/panels/10_0',
              },
            },
            {
              x: 0,
              y: 9,
              width: 24,
              height: 9,
              content: {
                '$ref': '#/spec/panels/10_4',
              },
            },
            {
              x: 0,
              y: 18,
              width: 24,
              height: 9,
              content: {
                '$ref': '#/spec/panels/10_5',
              },
            },
          ],
          repeatVariable: 'disk',
        },
      },
    ],
    variables: [
      {
        kind: 'ListVariable',
        spec: {
          display: {
            hidden: false,
          },
          allowAllValue: false,
          allowMultiple: false,
          sort: 'none',
          plugin: {
            kind: 'PrometheusLabelValuesVariable',
            spec: {
              labelName: 'job',
              matchers: [
                'go_threads{name="truenas"}',
              ],
            },
          },
          name: 'job',
        },
      },
      {
        kind: 'ListVariable',
        spec: {
          allowAllValue: false,
          allowMultiple: false,
          sort: 'none',
          plugin: {
            kind: 'PrometheusPromQLVariable',
            spec: {
              expr: 'go_threads{job="$job"}',
              labelName: 'instance',
            },
          },
          name: 'instance',
        },
      },
      {
        kind: 'ListVariable',
        spec: {
          name: 'disk',
          allowAllValue: false,
          allowMultiple: false,
          sort: 'none',
          plugin: {
            kind: 'PrometheusPromQLVariable',
            spec: {
              expr: 'truenas_disk_read_ops',
              labelName: 'disk',
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
