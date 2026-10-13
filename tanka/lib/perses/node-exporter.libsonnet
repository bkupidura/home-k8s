{
  kind: 'Dashboard',
  metadata: {
    name: 'node-exporter',
    createdAt: '2026-10-10T18:23:56.02125486Z',
    updatedAt: '2026-10-10T18:23:56.02125486Z',
    version: 0,
    tags: [
      'linux',
    ],
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'Node Exporter',
    },
    panels: {
      '0_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'CPU Busy',
            description: 'Busy state of all CPU cores together',
          },
          plugin: {
            kind: 'GaugeChart',
            spec: {
              calculation: 'last-number',
              format: {
                unit: 'percent',
              },
              max: 100,
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 85,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 95,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: "(((count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu))) - avg(sum by (mode)(rate(node_cpu_seconds_total{mode='idle',instance=\"$node\",job=\"$job\"}[$__rate_interval])))) * 100) / count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu))",
                    seriesNameFormat: '',
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
            name: 'Sys Load (5m avg)',
            description: 'Busy state of all CPU cores together (5 min average)',
          },
          plugin: {
            kind: 'GaugeChart',
            spec: {
              calculation: 'last-number',
              format: {
                unit: 'percent',
              },
              max: 100,
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 85,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 95,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'avg(node_load5{instance="$node",job="$job"}) /  count(count(node_cpu_seconds_total{instance="$node",job="$job"}) by (cpu)) * 100',
                  },
                },
              },
            },
          ],
        },
      },
      '0_10': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'SWAP Total',
            description: 'Total SWAP',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'none',
              format: {
                decimalPlaces: 0,
                unit: 'bytes',
              },
              mappings: [
                {
                  kind: 'Misc',
                  spec: {
                    result: {
                      value: 'N/A',
                    },
                    value: 'null',
                  },
                },
              ],
              thresholds: {
                steps: [
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'node_memory_SwapTotal_bytes{instance="$node",job="$job"}',
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
            name: 'Sys Load (15m avg)',
            description: 'Busy state of all CPU cores together (15 min average)',
          },
          plugin: {
            kind: 'GaugeChart',
            spec: {
              calculation: 'last-number',
              format: {
                unit: 'percent',
              },
              max: 100,
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 85,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 95,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'avg(node_load15{instance="$node",job="$job"}) /  count(count(node_cpu_seconds_total{instance="$node",job="$job"}) by (cpu)) * 100',
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
            name: 'RAM Used',
            description: 'Non available RAM memory',
          },
          plugin: {
            kind: 'GaugeChart',
            spec: {
              calculation: 'last-number',
              format: {
                decimalPlaces: 0,
                unit: 'percent',
              },
              max: 100,
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 80,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 90,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: '((node_memory_MemTotal_bytes{instance="$node",job="$job"} - node_memory_MemFree_bytes{instance="$node",job="$job"}) / (node_memory_MemTotal_bytes{instance="$node",job="$job"} )) * 100',
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
                    query: '100 - ((node_memory_MemAvailable_bytes{instance="$node",job="$job"} * 100) / node_memory_MemTotal_bytes{instance="$node",job="$job"})',
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
            name: 'SWAP Used',
            description: 'Used Swap',
          },
          plugin: {
            kind: 'GaugeChart',
            spec: {
              calculation: 'last-number',
              format: {
                unit: 'percent',
              },
              max: 100,
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 10,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 25,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: '((node_memory_SwapTotal_bytes{instance="$node",job="$job"} - node_memory_SwapFree_bytes{instance="$node",job="$job"}) / (node_memory_SwapTotal_bytes{instance="$node",job="$job"} )) * 100',
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
            name: 'Root FS Used',
            description: 'Used Root FS',
          },
          plugin: {
            kind: 'GaugeChart',
            spec: {
              calculation: 'last-number',
              format: {
                unit: 'percent',
              },
              max: 100,
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 80,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 90,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: '100 - ((node_filesystem_avail_bytes{instance="$node",job="$job",mountpoint="/",fstype!="rootfs"} * 100) / node_filesystem_size_bytes{instance="$node",job="$job",mountpoint="/",fstype!="rootfs"})',
                  },
                },
              },
            },
          ],
        },
      },
      '0_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'CPU Cores',
            description: 'Total number of CPU cores',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'none',
              format: {
                unit: 'decimal',
              },
              mappings: [
                {
                  kind: 'Misc',
                  spec: {
                    result: {
                      value: 'N/A',
                    },
                    value: 'null',
                  },
                },
              ],
              thresholds: {
                steps: [
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    minStep: '',
                    query: 'count(count(node_cpu_seconds_total{instance="$node",job="$job"}) by (cpu))',
                    seriesNameFormat: '',
                  },
                },
              },
            },
          ],
        },
      },
      '0_7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Uptime',
            description: 'System uptime',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'none',
              format: {
                decimalPlaces: 1,
                unit: 'seconds',
              },
              mappings: [
                {
                  kind: 'Misc',
                  spec: {
                    result: {
                      value: 'N/A',
                    },
                    value: 'null',
                  },
                },
              ],
              thresholds: {
                steps: [
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'node_time_seconds{instance="$node",job="$job"} - node_boot_time_seconds{instance="$node",job="$job"}',
                  },
                },
              },
            },
          ],
        },
      },
      '0_8': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'RootFS Total',
            description: 'Total RootFS',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'none',
              format: {
                decimalPlaces: 0,
                unit: 'bytes',
              },
              mappings: [
                {
                  kind: 'Misc',
                  spec: {
                    result: {
                      value: 'N/A',
                    },
                    value: 'null',
                  },
                },
              ],
              thresholds: {
                steps: [
                  {
                    color: 'rgba(237, 129, 40, 0.89)',
                    value: 70,
                  },
                  {
                    color: 'rgba(245, 54, 54, 0.9)',
                    value: 90,
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'node_filesystem_size_bytes{instance="$node",job="$job",mountpoint="/",fstype!="rootfs"}',
                  },
                },
              },
            },
          ],
        },
      },
      '0_9': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'RAM Total',
            description: 'Total RAM',
          },
          plugin: {
            kind: 'StatChart',
            spec: {
              calculation: 'last-number',
              colorMode: 'none',
              format: {
                decimalPlaces: 0,
                unit: 'bytes',
              },
              mappings: [
                {
                  kind: 'Misc',
                  spec: {
                    result: {
                      value: 'N/A',
                    },
                    value: 'null',
                  },
                },
              ],
              thresholds: {
                steps: [
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
                    datasource: {
                      kind: 'PrometheusDatasource',
                    },
                    query: 'node_memory_MemTotal_bytes{instance="$node",job="$job"}',
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
            name: 'Disk IOps Completed',
            description: 'The number (after merges) of I/O requests completed per second for the device',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_reads_completed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Reads completed',
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
                    query: 'rate(node_disk_writes_completed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Writes completed',
                  },
                },
              },
            },
          ],
        },
      },
      '10_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk R/W Data',
            description: 'The number of bytes read from or written to the device per second',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_read_bytes_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Read bytes',
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
                    query: 'rate(node_disk_written_bytes_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Written bytes',
                  },
                },
              },
            },
          ],
        },
      },
      '10_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk Average Wait Time',
            description: 'The average time for requests issued to the device to be served. This includes the time spent by the requests in queue and the time spent servicing them.',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_read_time_seconds_total{instance="$node",job="$job"}[$__rate_interval]) / rate(node_disk_reads_completed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - r_await',
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
                    query: 'rate(node_disk_write_time_seconds_total{instance="$node",job="$job"}[$__rate_interval]) / rate(node_disk_writes_completed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - w_await',
                  },
                },
              },
            },
          ],
        },
      },
      '10_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Average Queue Size',
            description: 'The average queue length of the requests that were issued to the device',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_io_time_weighted_seconds_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}}',
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
            name: 'Disk R/W Merged',
            description: 'The number of read and write requests merged per second that were queued to the device',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_reads_merged_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Read merged',
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
                    query: 'rate(node_disk_writes_merged_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Write merged',
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
            name: 'Time Spent Doing I/Os',
            description: 'Percentage of elapsed time during which I/O requests were issued to the device (bandwidth utilization for the device). Device saturation occurs when this value is close to 100% for devices serving requests serially.  But for devices  serving requests in parallel, such as RAID arrays and modern SSDs, this number does not reflect their performance limits.',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_io_time_seconds_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - IO',
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
                    query: 'rate(node_disk_discard_time_seconds_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - discard',
                  },
                },
              },
            },
          ],
        },
      },
      '10_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Instantaneous Queue Size',
            description: 'The number of outstanding requests at the instant the sample was taken. Incremented as requests are given to appropriate struct request_queue and decremented as they finish.',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_io_now{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - IO now',
                  },
                },
              },
            },
          ],
        },
      },
      '10_7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Disk IOps Discards completed / merged',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_discards_completed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Discards completed',
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
                    query: 'rate(node_disk_discards_merged_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Discards merged',
                  },
                },
              },
            },
          ],
        },
      },
      '11_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Filesystem space available',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: "node_filesystem_avail_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}} - Available',
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
                    query: "node_filesystem_free_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}} - Free',
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
                    query: "node_filesystem_size_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}} - Size',
                  },
                },
              },
            },
          ],
        },
      },
      '11_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'File Nodes Free',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: "node_filesystem_files_free{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}} - Free file nodes',
                  },
                },
              },
            },
          ],
        },
      },
      '11_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'File Descriptor',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_filefd_maximum{instance="$node",job="$job"}',
                    seriesNameFormat: 'Max open files',
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
                    query: 'node_filefd_allocated{instance="$node",job="$job"}',
                    seriesNameFormat: 'Open files',
                  },
                },
              },
            },
          ],
        },
      },
      '11_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'File Nodes Size',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: "node_filesystem_files{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}} - File nodes total',
                  },
                },
              },
            },
          ],
        },
      },
      '11_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Filesystem in ReadOnly / Error',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: "node_filesystem_readonly{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}} - ReadOnly',
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
                    query: "node_filesystem_device_error{instance=\"$node\",job=\"$job\",device!~'rootfs',fstype!~'tmpfs'}",
                    seriesNameFormat: '{{mountpoint}} - Device error',
                  },
                },
              },
            },
          ],
        },
      },
      '12_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic by Packets',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_packets_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive',
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
                    query: 'rate(node_network_transmit_packets_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Transmit',
                  },
                },
              },
            },
          ],
        },
      },
      '12_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Errors',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_errs_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive errors',
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
                    query: 'rate(node_network_transmit_errs_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Rransmit errors',
                  },
                },
              },
            },
          ],
        },
      },
      '12_10': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'ARP Entries',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_arp_entries{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ device }} - ARP entries',
                  },
                },
              },
            },
          ],
        },
      },
      '12_11': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'MTU',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_network_mtu_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ device }} - Bytes',
                  },
                },
              },
            },
          ],
        },
      },
      '12_12': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Speed',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_network_speed_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ device }} - Speed',
                  },
                },
              },
            },
          ],
        },
      },
      '12_13': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Queue Length',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_network_transmit_queue_length{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ device }} -   Interface transmit queue length',
                  },
                },
              },
            },
          ],
        },
      },
      '12_14': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Softnet Packets',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_softnet_processed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'CPU {{cpu}} - Processed',
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
                    query: 'rate(node_softnet_dropped_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'CPU {{cpu}} - Dropped',
                  },
                },
              },
            },
          ],
        },
      },
      '12_15': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Softnet Out of Quota',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_softnet_times_squeezed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'CPU {{cpu}} - Squeezed',
                  },
                },
              },
            },
          ],
        },
      },
      '12_16': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Operational Status',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_network_up{operstate="up",instance="$node",job="$job"}',
                    seriesNameFormat: '{{interface}} - Operational state UP',
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
                    query: 'node_network_carrier{instance="$node",job="$job"}',
                    seriesNameFormat: '{{device}} - Physical link state',
                  },
                },
              },
            },
          ],
        },
      },
      '12_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Drop',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_drop_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive drop',
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
                    query: 'rate(node_network_transmit_drop_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Transmit drop',
                  },
                },
              },
            },
          ],
        },
      },
      '12_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Compressed',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_compressed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive compressed',
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
                    query: 'rate(node_network_transmit_compressed_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Transmit compressed',
                  },
                },
              },
            },
          ],
        },
      },
      '12_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Multicast',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_multicast_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive multicast',
                  },
                },
              },
            },
          ],
        },
      },
      '12_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Fifo',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_fifo_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive fifo',
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
                    query: 'rate(node_network_transmit_fifo_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Transmit fifo',
                  },
                },
              },
            },
          ],
        },
      },
      '12_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Frame',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_frame_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Receive frame',
                  },
                },
              },
            },
          ],
        },
      },
      '12_7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Carrier',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_transmit_carrier_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Statistic transmit_carrier',
                  },
                },
              },
            },
          ],
        },
      },
      '12_8': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Network Traffic Colls',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_transmit_colls_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Transmit colls',
                  },
                },
              },
            },
          ],
        },
      },
      '12_9': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'NF Contrack',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_nf_conntrack_entries{instance="$node",job="$job"}',
                    seriesNameFormat: 'NF conntrack entries',
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
                    query: 'node_nf_conntrack_entries_limit{instance="$node",job="$job"}',
                    seriesNameFormat: 'NF conntrack limit',
                  },
                },
              },
            },
          ],
        },
      },
      '13_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Sockstat TCP',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_sockstat_TCP_alloc{instance="$node",job="$job"}',
                    seriesNameFormat: 'TCP_alloc - Allocated sockets',
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
                    query: 'node_sockstat_TCP_inuse{instance="$node",job="$job"}',
                    seriesNameFormat: 'TCP_inuse - Tcp sockets currently in use',
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
                    query: 'node_sockstat_TCP_mem{instance="$node",job="$job"}',
                    seriesNameFormat: 'TCP_mem - Used memory for tcp',
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
                    query: 'node_sockstat_TCP_orphan{instance="$node",job="$job"}',
                    seriesNameFormat: 'TCP_orphan - Orphan sockets',
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
                    query: 'node_sockstat_TCP_tw{instance="$node",job="$job"}',
                    seriesNameFormat: 'TCP_tw - Sockets wating close',
                  },
                },
              },
            },
          ],
        },
      },
      '13_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Sockstat UDP',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_sockstat_UDPLITE_inuse{instance="$node",job="$job"}',
                    seriesNameFormat: 'UDPLITE_inuse - Udplite sockets currently in use',
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
                    query: 'node_sockstat_UDP_inuse{instance="$node",job="$job"}',
                    seriesNameFormat: 'UDP_inuse - Udp sockets currently in use',
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
                    query: 'node_sockstat_UDP_mem{instance="$node",job="$job"}',
                    seriesNameFormat: 'UDP_mem - Used memory for udp',
                  },
                },
              },
            },
          ],
        },
      },
      '13_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Sockstat Used',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_sockstat_sockets_used{instance="$node",job="$job"}',
                    seriesNameFormat: 'Sockets_used - Sockets currently in use',
                  },
                },
              },
            },
          ],
        },
      },
      '13_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Sockstat Memory Size',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_sockstat_TCP_mem_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'mem_bytes - TCP sockets in that state',
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
                    query: 'node_sockstat_UDP_mem_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'mem_bytes - UDP sockets in that state',
                  },
                },
              },
            },
          ],
        },
      },
      '13_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Sockstat FRAG / RAW',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_sockstat_FRAG_inuse{instance="$node",job="$job"}',
                    seriesNameFormat: 'FRAG_inuse - Frag sockets currently in use',
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
                    query: 'node_sockstat_FRAG_memory{instance="$node",job="$job"}',
                    seriesNameFormat: 'FRAG_memory - Used memory for frag',
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
                    query: 'node_sockstat_RAW_inuse{instance="$node",job="$job"}',
                    seriesNameFormat: 'RAW_inuse - Raw sockets currently in use',
                  },
                },
              },
            },
          ],
        },
      },
      '14_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Netstat IP In / Out Octets',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_IpExt_InOctets{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InOctets - Received octets',
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
                    query: 'rate(node_netstat_IpExt_OutOctets{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'OutOctets - Sent octets',
                  },
                },
              },
            },
          ],
        },
      },
      '14_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Netstat IP Forwarding',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Ip_Forwarding{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Forwarding - IP forwarding',
                  },
                },
              },
            },
          ],
        },
      },
      '14_10': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'TCP Direct Transition',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Tcp_ActiveOpens{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'ActiveOpens - TCP connections that have made a direct transition to the SYN-SENT state from the CLOSED state',
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
                    query: 'rate(node_netstat_Tcp_PassiveOpens{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'PassiveOpens - TCP connections that have made a direct transition to the SYN-RCVD state from the LISTEN state',
                  },
                },
              },
            },
          ],
        },
      },
      '14_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'ICMP In / Out',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Icmp_InMsgs{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InMsgs -  Messages which the entity received. Note that this counter includes all those counted by icmpInErrors',
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
                    query: 'rate(node_netstat_Icmp_OutMsgs{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'OutMsgs - Messages which this entity attempted to send. Note that this counter includes all those counted by icmpOutErrors',
                  },
                },
              },
            },
          ],
        },
      },
      '14_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'ICMP Errors',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Icmp_InErrors{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InErrors - Messages which the entity received but determined as having ICMP-specific errors (bad ICMP checksums, bad length, etc.)',
                  },
                },
              },
            },
          ],
        },
      },
      '14_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'UDP In / Out',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Udp_InDatagrams{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InDatagrams - Datagrams received',
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
                    query: 'rate(node_netstat_Udp_OutDatagrams{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'OutDatagrams - Datagrams sent',
                  },
                },
              },
            },
          ],
        },
      },
      '14_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'UDP Errors',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Udp_InErrors{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InErrors - UDP Datagrams that could not be delivered to an application',
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
                    query: 'rate(node_netstat_Udp_NoPorts{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'NoPorts - UDP Datagrams received on a port with no listener',
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
                    query: 'rate(node_netstat_UdpLite_InErrors{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InErrors Lite - UDPLite Datagrams that could not be delivered to an application',
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
                    query: 'rate(node_netstat_Udp_RcvbufErrors{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'RcvbufErrors - UDP buffer errors received',
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
                    query: 'rate(node_netstat_Udp_SndbufErrors{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'SndbufErrors - UDP buffer errors send',
                  },
                },
              },
            },
          ],
        },
      },
      '14_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'TCP In / Out',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_Tcp_InSegs{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InSegs - Segments received, including those received in error. This count includes segments received on currently established connections',
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
                    query: 'rate(node_netstat_Tcp_OutSegs{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'OutSegs - Segments sent, including those on current connections but excluding those containing only retransmitted octets',
                  },
                },
              },
            },
          ],
        },
      },
      '14_7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'TCP Errors',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_TcpExt_ListenOverflows{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'ListenOverflows - Times the listen queue of a socket overflowed',
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
                    query: 'rate(node_netstat_TcpExt_ListenDrops{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'ListenDrops - SYNs to LISTEN sockets ignored',
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
                    query: 'rate(node_netstat_TcpExt_TCPSynRetrans{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'TCPSynRetrans - SYN-SYN/ACK retransmits to break down retransmissions in SYN, fast/timeout retransmits',
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
                    query: 'rate(node_netstat_Tcp_RetransSegs{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'RetransSegs - Segments retransmitted - that is, the number of TCP segments transmitted containing one or more previously transmitted octets',
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
                    query: 'rate(node_netstat_Tcp_InErrs{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'InErrs - Segments received in error (e.g., bad TCP checksums)',
                  },
                },
              },
            },
          ],
        },
      },
      '14_8': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'TCP Connections',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_netstat_Tcp_CurrEstab{instance="$node",job="$job"}',
                    seriesNameFormat: 'CurrEstab - TCP connections for which the current state is either ESTABLISHED or CLOSE- WAIT',
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
                    query: 'node_netstat_Tcp_MaxConn{instance="$node",job="$job"}',
                    seriesNameFormat: 'MaxConn - Limit on the total number of TCP connections the entity can support (Dinamic is "-1")',
                  },
                },
              },
            },
          ],
        },
      },
      '14_9': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'TCP SynCookie',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_netstat_TcpExt_SyncookiesFailed{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'SyncookiesFailed - Invalid SYN cookies received',
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
                    query: 'rate(node_netstat_TcpExt_SyncookiesRecv{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'SyncookiesRecv - SYN cookies received',
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
                    query: 'rate(node_netstat_TcpExt_SyncookiesSent{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'SyncookiesSent - SYN cookies sent',
                  },
                },
              },
            },
          ],
        },
      },
      '15_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Node Exporter Scrape Time',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_scrape_collector_duration_seconds{instance="$node",job="$job"}',
                    seriesNameFormat: '{{collector}} - Scrape duration',
                  },
                },
              },
            },
          ],
        },
      },
      '15_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Node Exporter Scrape',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_scrape_collector_success{instance="$node",job="$job"}',
                    seriesNameFormat: '{{collector}} - Scrape success',
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
                    query: 'node_textfile_scrape_error{instance="$node",job="$job"}',
                    seriesNameFormat: '{{collector}} - Scrape textfile error (1 = true)',
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
            name: 'CPU Basic',
            description: 'Basic CPU info',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'sum by (instance)(rate(node_cpu_seconds_total{mode="system",instance="$node",job="$job"}[$__rate_interval])) * 100',
                    seriesNameFormat: 'Busy System',
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
                    query: "sum by (instance)(rate(node_cpu_seconds_total{mode='user',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Busy User',
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
                    query: "sum by (instance)(rate(node_cpu_seconds_total{mode='iowait',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Busy Iowait',
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
                    query: 'sum by (instance)(rate(node_cpu_seconds_total{mode=~".*irq",instance="$node",job="$job"}[$__rate_interval])) * 100',
                    seriesNameFormat: 'Busy IRQs',
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
                    query: "sum (rate(node_cpu_seconds_total{mode!='idle',mode!='user',mode!='system',mode!='iowait',mode!='irq',mode!='softirq',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Busy Other',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='idle',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Idle',
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
            name: 'Memory Basic',
            description: 'Basic memory usage',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_MemTotal_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'RAM Total',
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
                    query: 'node_memory_MemTotal_bytes{instance="$node",job="$job"} - node_memory_MemFree_bytes{instance="$node",job="$job"} - (node_memory_Cached_bytes{instance="$node",job="$job"} + node_memory_Buffers_bytes{instance="$node",job="$job"})',
                    seriesNameFormat: 'RAM Used',
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
                    query: 'node_memory_Cached_bytes{instance="$node",job="$job"} + node_memory_Buffers_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'RAM Cache + Buffer',
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
                    query: 'node_memory_MemFree_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'RAM Free',
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
                    query: '(node_memory_SwapTotal_bytes{instance="$node",job="$job"} - node_memory_SwapFree_bytes{instance="$node",job="$job"})',
                    seriesNameFormat: 'SWAP Used',
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
            name: 'Network Traffic Basic',
            description: 'Basic network info per interface',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_bytes_total{instance="$node",job="$job"}[$__rate_interval])*8',
                    seriesNameFormat: 'recv {{device}}',
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
                    query: 'rate(node_network_transmit_bytes_total{instance="$node",job="$job"}[$__rate_interval])*8',
                    seriesNameFormat: 'trans {{device}} ',
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
            name: 'Disk Space Used Basic',
            description: 'Disk space used of all filesystems mounted',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: "100 - ((node_filesystem_avail_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'} * 100) / node_filesystem_size_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'})",
                    seriesNameFormat: '{{mountpoint}}',
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
            name: 'CPU',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    minStep: '10s',
                    query: 'sum by (mode)(rate(node_cpu_seconds_total{mode="system",instance="$node",job="$job"}[$__rate_interval])) * 100',
                    seriesNameFormat: 'System - Processes executing in kernel mode',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='user',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'User - Normal processes executing in user mode',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='nice',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Nice - Niced processes executing in user mode',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='idle',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Idle - Waiting for something to happen',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='iowait',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Iowait - Waiting for I/O to complete',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='irq',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Irq - Servicing interrupts',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='softirq',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Softirq - Servicing softirqs',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='steal',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Steal - Time spent in other operating systems when running in a virtualized environment',
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
                    query: "sum by (mode)(rate(node_cpu_seconds_total{mode='guest',instance=\"$node\",job=\"$job\"}[$__rate_interval])) * 100",
                    seriesNameFormat: 'Guest - Time spent running a virtual CPU for a guest operating system',
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
            name: 'Memory Stack',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_MemTotal_bytes{instance="$node",job="$job"} - node_memory_MemFree_bytes{instance="$node",job="$job"} - node_memory_Buffers_bytes{instance="$node",job="$job"} - node_memory_Cached_bytes{instance="$node",job="$job"} - node_memory_Slab_bytes{instance="$node",job="$job"} - node_memory_PageTables_bytes{instance="$node",job="$job"} - node_memory_SwapCached_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Apps - Memory used by user-space applications',
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
                    query: 'node_memory_PageTables_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'PageTables - Memory used to map between virtual and physical memory addresses',
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
                    query: 'node_memory_SwapCached_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'SwapCache - Memory that keeps track of pages that have been fetched from swap but not yet been modified',
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
                    query: 'node_memory_Slab_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Slab - Memory used by the kernel to cache data structures for its own use (caches like inode, dentry, etc)',
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
                    query: 'node_memory_Cached_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Cache - Parked file data (file content) cache',
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
                    query: 'node_memory_Buffers_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Buffers - Block device (e.g. harddisk) cache',
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
                    query: 'node_memory_MemFree_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Unused - Free memory unassigned',
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
                    query: '(node_memory_SwapTotal_bytes{instance="$node",job="$job"} - node_memory_SwapFree_bytes{instance="$node",job="$job"})',
                    seriesNameFormat: 'Swap - Swap space used',
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
                    query: 'node_memory_HardwareCorrupted_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Hardware Corrupted - Amount of RAM that the kernel identified as corrupted / not working',
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
            name: 'Network Traffic',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_network_receive_bytes_total{instance="$node",job="$job"}[$__rate_interval])*8',
                    seriesNameFormat: '{{device}} - Receive',
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
                    query: 'rate(node_network_transmit_bytes_total{instance="$node",job="$job"}[$__rate_interval])*8',
                    seriesNameFormat: '{{device}} - Transmit',
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
            name: 'Disk Space Used',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: "node_filesystem_size_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'} - node_filesystem_avail_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'}",
                    seriesNameFormat: '{{mountpoint}}',
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
            name: 'Disk IOps',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_reads_completed_total{instance="$node",job="$job",device=~"$diskdevices"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Reads completed',
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
                    query: 'rate(node_disk_writes_completed_total{instance="$node",job="$job",device=~"$diskdevices"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Writes completed',
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
            name: 'I/O Usage Read / Write',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_read_bytes_total{instance="$node",job="$job",device=~"$diskdevices"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Successfully read bytes',
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
                    query: 'rate(node_disk_written_bytes_total{instance="$node",job="$job",device=~"$diskdevices"}[$__rate_interval])',
                    seriesNameFormat: '{{device}} - Successfully written bytes',
                  },
                },
              },
            },
          ],
        },
      },
      '2_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'I/O Utilization',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_disk_io_time_seconds_total{instance="$node",job="$job",device=~"$diskdevices"} [$__rate_interval])',
                    seriesNameFormat: '{{device}}',
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
            name: 'Memory Active / Inactive',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Inactive_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Inactive - Memory which has been less recently used.  It is more eligible to be reclaimed for other purposes',
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
                    query: 'node_memory_Active_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Active - Memory that has been used more recently and usually not reclaimed unless absolutely necessary',
                  },
                },
              },
            },
          ],
        },
      },
      '3_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Commited',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Committed_AS_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Committed_AS - Amount of memory presently allocated on the system',
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
                    query: 'node_memory_CommitLimit_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'CommitLimit - Amount of  memory currently available to be allocated on the system',
                  },
                },
              },
            },
          ],
        },
      },
      '3_10': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory HugePages Counter',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_HugePages_Free{instance="$node",job="$job"}',
                    seriesNameFormat: 'HugePages_Free - Huge pages in the pool that are not yet allocated',
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
                    query: 'node_memory_HugePages_Rsvd{instance="$node",job="$job"}',
                    seriesNameFormat: 'HugePages_Rsvd - Huge pages for which a commitment to allocate from the pool has been made, but no allocation has yet been made',
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
                    query: 'node_memory_HugePages_Surp{instance="$node",job="$job"}',
                    seriesNameFormat: 'HugePages_Surp - Huge pages in the pool above the value in /proc/sys/vm/nr_hugepages',
                  },
                },
              },
            },
          ],
        },
      },
      '3_11': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory HugePages Size',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_HugePages_Total{instance="$node",job="$job"}',
                    seriesNameFormat: 'HugePages - Total size of the pool of huge pages',
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
                    query: 'node_memory_Hugepagesize_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Hugepagesize - Huge Page size',
                  },
                },
              },
            },
          ],
        },
      },
      '3_12': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory DirectMap',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_DirectMap1G_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'DirectMap1G - Amount of pages mapped as this size',
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
                    query: 'node_memory_DirectMap2M_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'DirectMap2M - Amount of pages mapped as this size',
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
                    query: 'node_memory_DirectMap4k_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'DirectMap4K - Amount of pages mapped as this size',
                  },
                },
              },
            },
          ],
        },
      },
      '3_13': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Unevictable and MLocked',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Unevictable_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: "Unevictable - Amount of unevictable memory that can't be swapped out for a variety of reasons",
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
                    query: 'node_memory_Mlocked_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'MLocked - Size of pages locked to memory using the mlock() system call',
                  },
                },
              },
            },
          ],
        },
      },
      '3_14': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory NFS',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_NFS_Unstable_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'NFS Unstable - Memory in NFS pages sent to the server, but not yet commited to the storage',
                  },
                },
              },
            },
          ],
        },
      },
      '3_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Active / Inactive Detail',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Inactive_file_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Inactive_file - File-backed memory on inactive LRU list',
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
                    query: 'node_memory_Inactive_anon_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Inactive_anon - Anonymous and swap cache on inactive LRU list, including tmpfs (shmem)',
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
                    query: 'node_memory_Active_file_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Active_file - File-backed memory on active LRU list',
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
                    query: 'node_memory_Active_anon_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Active_anon - Anonymous and swap cache on active least-recently-used (LRU) list, including tmpfs',
                  },
                },
              },
            },
          ],
        },
      },
      '3_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Writeback and Dirty',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Writeback_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Writeback - Memory which is actively being written back to disk',
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
                    query: 'node_memory_WritebackTmp_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'WritebackTmp - Memory used by FUSE for temporary writeback buffers',
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
                    query: 'node_memory_Dirty_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Dirty - Memory which is waiting to get written back to the disk',
                  },
                },
              },
            },
          ],
        },
      },
      '3_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Shared and Mapped',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Mapped_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Mapped - Used memory in mapped pages files which have been mmaped, such as libraries',
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
                    query: 'node_memory_Shmem_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Shmem - Used shared memory (shared between several processes, thus including RAM disks)',
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
                    query: 'node_memory_ShmemHugePages_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'ShmemHugePages - Memory used by shared memory (shmem) and tmpfs allocated  with huge pages',
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
                    query: 'node_memory_ShmemPmdMapped_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'ShmemPmdMapped - Ammount of shared (shmem/tmpfs) memory backed by huge pages',
                  },
                },
              },
            },
          ],
        },
      },
      '3_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Slab',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_SUnreclaim_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'SUnreclaim - Part of Slab, that cannot be reclaimed on memory pressure',
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
                    query: 'node_memory_SReclaimable_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'SReclaimable - Part of Slab, that might be reclaimed, such as caches',
                  },
                },
              },
            },
          ],
        },
      },
      '3_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Vmalloc',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_VmallocChunk_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'VmallocChunk - Largest contigious block of vmalloc area which is free',
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
                    query: 'node_memory_VmallocTotal_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'VmallocTotal - Total size of vmalloc memory area',
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
                    query: 'node_memory_VmallocUsed_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'VmallocUsed - Amount of vmalloc area which is used',
                  },
                },
              },
            },
          ],
        },
      },
      '3_7': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Bounce',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_Bounce_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Bounce - Memory used for block device bounce buffers',
                  },
                },
              },
            },
          ],
        },
      },
      '3_8': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Anonymous',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_AnonHugePages_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'AnonHugePages - Memory in anonymous huge pages',
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
                    query: 'node_memory_AnonPages_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'AnonPages - Memory in user pages not backed by files',
                  },
                },
              },
            },
          ],
        },
      },
      '3_9': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Kernel / CPU',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_memory_KernelStack_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'KernelStack - Kernel memory stack. This is not reclaimable',
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
                    query: 'node_memory_Percpu_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'PerCPU - Per CPU memory allocated dynamically by loadable modules',
                  },
                },
              },
            },
          ],
        },
      },
      '4_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Pages In / Out',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_vmstat_pgpgin{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pagesin - Page in operations',
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
                    query: 'rate(node_vmstat_pgpgout{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pagesout - Page out operations',
                  },
                },
              },
            },
          ],
        },
      },
      '4_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Pages Swap In / Out',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_vmstat_pswpin{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pswpin - Pages swapped in',
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
                    query: 'rate(node_vmstat_pswpout{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pswpout - Pages swapped out',
                  },
                },
              },
            },
          ],
        },
      },
      '4_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Memory Page Faults',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_vmstat_pgfault{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pgfault - Page major and minor fault operations',
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
                    query: 'rate(node_vmstat_pgmajfault{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pgmajfault - Major page fault operations',
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
                    query: 'rate(node_vmstat_pgfault{instance="$node",job="$job"}[$__rate_interval])  - rate(node_vmstat_pgmajfault{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Pgminfault - Minor page fault operations',
                  },
                },
              },
            },
          ],
        },
      },
      '4_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'OOM Killer',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_vmstat_oom_kill{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'oom killer invocations ',
                  },
                },
              },
            },
          ],
        },
      },
      '5_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Time Syncronized Drift',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_timex_estimated_error_seconds{instance="$node",job="$job"}',
                    seriesNameFormat: 'Estimated error in seconds',
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
                    query: 'node_timex_offset_seconds{instance="$node",job="$job"}',
                    seriesNameFormat: 'Time offset in between local system and reference clock',
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
                    query: 'node_timex_maxerror_seconds{instance="$node",job="$job"}',
                    seriesNameFormat: 'Maximum error in seconds',
                  },
                },
              },
            },
          ],
        },
      },
      '5_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Time PLL Adjust',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_timex_loop_time_constant{instance="$node",job="$job"}',
                    seriesNameFormat: 'Phase-locked loop time adjust',
                  },
                },
              },
            },
          ],
        },
      },
      '5_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Time Syncronized Status',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_timex_sync_status{instance="$node",job="$job"}',
                    seriesNameFormat: 'Is clock synchronized to a reliable server (1 = yes, 0 = no)',
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
                    query: 'node_timex_frequency_adjustment_ratio{instance="$node",job="$job"}',
                    seriesNameFormat: 'Local clock frequency adjustment',
                  },
                },
              },
            },
          ],
        },
      },
      '5_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Time Misc',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_timex_tick_seconds{instance="$node",job="$job"}',
                    seriesNameFormat: 'Seconds between clock ticks',
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
                    query: 'node_timex_tai_offset_seconds{instance="$node",job="$job"}',
                    seriesNameFormat: 'International Atomic Time (TAI) offset',
                  },
                },
              },
            },
          ],
        },
      },
      '6_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Processes Status',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_procs_blocked{instance="$node",job="$job"}',
                    seriesNameFormat: 'Processes blocked waiting for I/O to complete',
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
                    query: 'node_procs_running{instance="$node",job="$job"}',
                    seriesNameFormat: 'Processes in runnable state',
                  },
                },
              },
            },
          ],
        },
      },
      '6_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Processes State',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_processes_state{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ state }}',
                  },
                },
              },
            },
          ],
        },
      },
      '6_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Processes  Forks',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_forks_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Processes forks second',
                  },
                },
              },
            },
          ],
        },
      },
      '6_3': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Processes Memory',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(process_virtual_memory_bytes{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Processes virtual memory size in bytes',
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
                    query: 'process_resident_memory_max_bytes{instance="$node",job="$job"}',
                    seriesNameFormat: 'Maximum amount of virtual memory available in bytes',
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
                    query: 'rate(process_virtual_memory_bytes{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Processes virtual memory size in bytes',
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
                    query: 'rate(process_virtual_memory_max_bytes{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Maximum amount of virtual memory available in bytes',
                  },
                },
              },
            },
          ],
        },
      },
      '6_4': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'PIDs Number and Limit',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_processes_pids{instance="$node",job="$job"}',
                    seriesNameFormat: 'Number of PIDs',
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
                    query: 'node_processes_max_processes{instance="$node",job="$job"}',
                    seriesNameFormat: 'PIDs limit',
                  },
                },
              },
            },
          ],
        },
      },
      '6_5': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Process schedule stats Running / Waiting',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_schedstat_running_seconds_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'CPU {{ cpu }} - seconds spent running a process',
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
                    query: 'rate(node_schedstat_waiting_seconds_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'CPU {{ cpu }} - seconds spent by processing waiting for this CPU',
                  },
                },
              },
            },
          ],
        },
      },
      '6_6': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Threads Number and Limit',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_processes_threads{instance="$node",job="$job"}',
                    seriesNameFormat: 'Allocated threads',
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
                    query: 'node_processes_max_threads{instance="$node",job="$job"}',
                    seriesNameFormat: 'Threads limit',
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
            name: 'Context Switches / Interrupts',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_context_switches_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Context switches',
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
                    query: 'rate(node_intr_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Interrupts',
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
            name: 'System Load',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_load1{instance="$node",job="$job"}',
                    seriesNameFormat: 'Load 1m',
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
                    query: 'node_load5{instance="$node",job="$job"}',
                    seriesNameFormat: 'Load 5m',
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
                    query: 'node_load15{instance="$node",job="$job"}',
                    seriesNameFormat: 'Load 15m',
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
            name: 'Interrupts Detail',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_interrupts_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{ type }} - {{ info }}',
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
            name: 'Schedule timeslices executed by each cpu',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_schedstat_timeslices_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'CPU {{ cpu }}',
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
            name: 'Entropy',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_entropy_available_bits{instance="$node",job="$job"}',
                    seriesNameFormat: 'Entropy available to random number generators',
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
            name: 'CPU time spent in user and system contexts',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(process_cpu_seconds_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: 'Time spent',
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
            name: 'File Descriptors',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'process_max_fds{instance="$node",job="$job"}',
                    seriesNameFormat: 'Maximum open file descriptors',
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
                    query: 'process_open_fds{instance="$node",job="$job"}',
                    seriesNameFormat: 'Open file descriptors',
                  },
                },
              },
            },
          ],
        },
      },
      '8_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Hardware temperature monitor',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_hwmon_temp_celsius{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ chip }} {{ sensor }} temp',
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
                    query: 'node_hwmon_temp_crit_alarm_celsius{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ chip }} {{ sensor }} Critical Alarm',
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
                    query: 'node_hwmon_temp_crit_celsius{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ chip }} {{ sensor }} Critical',
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
                    query: 'node_hwmon_temp_crit_hyst_celsius{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ chip }} {{ sensor }} Critical Historical',
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
                    query: 'node_hwmon_temp_max_celsius{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ chip }} {{ sensor }} Max',
                  },
                },
              },
            },
          ],
        },
      },
      '8_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Throttle cooling device',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_cooling_device_cur_state{instance="$node",job="$job"}',
                    seriesNameFormat: 'Current {{ name }} in {{ type }}',
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
                    query: 'node_cooling_device_max_state{instance="$node",job="$job"}',
                    seriesNameFormat: 'Max {{ name }} in {{ type }}',
                  },
                },
              },
            },
          ],
        },
      },
      '8_2': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Power supply',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_power_supply_online{instance="$node",job="$job"}',
                    seriesNameFormat: '{{ power_supply }} online',
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
            name: 'Systemd Sockets',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'rate(node_systemd_socket_accepted_connections_total{instance="$node",job="$job"}[$__rate_interval])',
                    seriesNameFormat: '{{ name }} Connections',
                  },
                },
              },
            },
          ],
        },
      },
      '9_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Systemd Units State',
          },
          plugin: {
            kind: 'TimeSeriesChart',
            spec: {},
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
                    query: 'node_systemd_units{instance="$node",job="$job",state="activating"}',
                    seriesNameFormat: 'Activating',
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
                    query: 'node_systemd_units{instance="$node",job="$job",state="active"}',
                    seriesNameFormat: 'Active',
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
                    query: 'node_systemd_units{instance="$node",job="$job",state="deactivating"}',
                    seriesNameFormat: 'Deactivating',
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
                    query: 'node_systemd_units{instance="$node",job="$job",state="failed"}',
                    seriesNameFormat: 'Failed',
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
                    query: 'node_systemd_units{instance="$node",job="$job",state="inactive"}',
                    seriesNameFormat: 'Inactive',
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
            title: 'Quick CPU / Mem / Disk',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 3,
              height: 4,
              content: {
                '$ref': '#/spec/panels/0_0',
              },
            },
            {
              x: 3,
              y: 0,
              width: 3,
              height: 4,
              content: {
                '$ref': '#/spec/panels/0_1',
              },
            },
            {
              x: 6,
              y: 0,
              width: 3,
              height: 4,
              content: {
                '$ref': '#/spec/panels/0_2',
              },
            },
            {
              x: 9,
              y: 0,
              width: 3,
              height: 4,
              content: {
                '$ref': '#/spec/panels/0_3',
              },
            },
            {
              x: 12,
              y: 0,
              width: 3,
              height: 4,
              content: {
                '$ref': '#/spec/panels/0_4',
              },
            },
            {
              x: 15,
              y: 0,
              width: 3,
              height: 4,
              content: {
                '$ref': '#/spec/panels/0_5',
              },
            },
            {
              x: 18,
              y: 0,
              width: 2,
              height: 2,
              content: {
                '$ref': '#/spec/panels/0_6',
              },
            },
            {
              x: 20,
              y: 0,
              width: 4,
              height: 2,
              content: {
                '$ref': '#/spec/panels/0_7',
              },
            },
            {
              x: 18,
              y: 2,
              width: 2,
              height: 2,
              content: {
                '$ref': '#/spec/panels/0_8',
              },
            },
            {
              x: 20,
              y: 2,
              width: 2,
              height: 2,
              content: {
                '$ref': '#/spec/panels/0_9',
              },
            },
            {
              x: 22,
              y: 2,
              width: 2,
              height: 2,
              content: {
                '$ref': '#/spec/panels/0_10',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Basic CPU / Mem / Net / Disk',
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
                '$ref': '#/spec/panels/1_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_1',
              },
            },
            {
              x: 0,
              y: 7,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_2',
              },
            },
            {
              x: 12,
              y: 7,
              width: 12,
              height: 7,
              content: {
                '$ref': '#/spec/panels/1_3',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'CPU / Memory / Net / Disk',
            collapse: {
              open: true,
            },
          },
          items: [
            {
              x: 0,
              y: 0,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_1',
              },
            },
            {
              x: 0,
              y: 12,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_2',
              },
            },
            {
              x: 12,
              y: 12,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_3',
              },
            },
            {
              x: 0,
              y: 24,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_4',
              },
            },
            {
              x: 12,
              y: 24,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_5',
              },
            },
            {
              x: 0,
              y: 36,
              width: 12,
              height: 12,
              content: {
                '$ref': '#/spec/panels/2_6',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Memory Meminfo',
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
                '$ref': '#/spec/panels/3_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_4',
              },
            },
            {
              x: 12,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_5',
              },
            },
            {
              x: 0,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_6',
              },
            },
            {
              x: 12,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_7',
              },
            },
            {
              x: 0,
              y: 40,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_8',
              },
            },
            {
              x: 12,
              y: 40,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_9',
              },
            },
            {
              x: 0,
              y: 50,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_10',
              },
            },
            {
              x: 12,
              y: 50,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_11',
              },
            },
            {
              x: 0,
              y: 60,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_12',
              },
            },
            {
              x: 12,
              y: 60,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_13',
              },
            },
            {
              x: 0,
              y: 70,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/3_14',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Memory Vmstat',
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
                '$ref': '#/spec/panels/4_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/4_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/4_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/4_3',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'System Timesync',
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
                '$ref': '#/spec/panels/5_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/5_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/5_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/5_3',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'System Processes',
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
                '$ref': '#/spec/panels/6_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/6_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/6_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/6_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/6_4',
              },
            },
            {
              x: 12,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/6_5',
              },
            },
            {
              x: 12,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/6_6',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'System Misc',
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
                '$ref': '#/spec/panels/7_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/7_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/7_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/7_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/7_4',
              },
            },
            {
              x: 12,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/7_5',
              },
            },
            {
              x: 0,
              y: 30,
              width: 12,
              height: 10,
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
            title: 'Hardware Misc',
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
                '$ref': '#/spec/panels/8_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/8_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/8_2',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Systemd',
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
                '$ref': '#/spec/panels/9_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/9_1',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Storage Disk',
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
                '$ref': '#/spec/panels/10_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_4',
              },
            },
            {
              x: 12,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_5',
              },
            },
            {
              x: 0,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_6',
              },
            },
            {
              x: 12,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/10_7',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Storage Filesystem',
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
                '$ref': '#/spec/panels/11_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/11_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/11_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/11_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/11_4',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Network Traffic',
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
                '$ref': '#/spec/panels/12_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_4',
              },
            },
            {
              x: 12,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_5',
              },
            },
            {
              x: 0,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_6',
              },
            },
            {
              x: 12,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_7',
              },
            },
            {
              x: 0,
              y: 40,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_8',
              },
            },
            {
              x: 12,
              y: 40,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_9',
              },
            },
            {
              x: 0,
              y: 50,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_10',
              },
            },
            {
              x: 12,
              y: 50,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_11',
              },
            },
            {
              x: 0,
              y: 60,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_12',
              },
            },
            {
              x: 12,
              y: 60,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_13',
              },
            },
            {
              x: 0,
              y: 70,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_14',
              },
            },
            {
              x: 12,
              y: 70,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_15',
              },
            },
            {
              x: 0,
              y: 80,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/12_16',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Network Sockstat',
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
                '$ref': '#/spec/panels/13_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/13_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/13_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/13_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/13_4',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Network Netstat',
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
                '$ref': '#/spec/panels/14_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_1',
              },
            },
            {
              x: 0,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_2',
              },
            },
            {
              x: 12,
              y: 10,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_3',
              },
            },
            {
              x: 0,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_4',
              },
            },
            {
              x: 12,
              y: 20,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_5',
              },
            },
            {
              x: 0,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_6',
              },
            },
            {
              x: 12,
              y: 30,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_7',
              },
            },
            {
              x: 0,
              y: 40,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_8',
              },
            },
            {
              x: 12,
              y: 40,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_9',
              },
            },
            {
              x: 0,
              y: 50,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/14_10',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Node Exporter',
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
                '$ref': '#/spec/panels/15_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 10,
              content: {
                '$ref': '#/spec/panels/15_1',
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
            name: 'datasource',
            hidden: false,
          },
          defaultValue: 'Default (victoriametrics from global)',
          allowAllValue: false,
          allowMultiple: false,
          plugin: {
            kind: 'DatasourceVariable',
            spec: {
              datasourcePluginKind: 'PrometheusDatasource',
            },
          },
          name: 'DS_PROMETHEUS',
        },
      },
      {
        kind: 'ListVariable',
        spec: {
          display: {
            name: 'Job',
            hidden: false,
          },
          defaultValue: 'kubernetes-service-endpoints',
          allowAllValue: false,
          allowMultiple: false,
          sort: 'alphabetical-asc',
          plugin: {
            kind: 'PrometheusLabelValuesVariable',
            spec: {
              labelName: 'job',
              matchers: [
                'node_uname_info',
              ],
            },
          },
          name: 'job',
        },
      },
      {
        kind: 'ListVariable',
        spec: {
          display: {
            name: 'Host:',
            hidden: false,
          },
          allowAllValue: false,
          allowMultiple: false,
          sort: 'alphabetical-asc',
          plugin: {
            kind: 'PrometheusLabelValuesVariable',
            spec: {
              labelName: 'instance',
              matchers: [
                'node_uname_info{job="$job"}',
              ],
            },
          },
          name: 'node',
        },
      },
      {
        kind: 'ListVariable',
        spec: {
          display: {
            hidden: true,
          },
          defaultValue: '[a-z]+|nvme[0-9]+n[0-9]+',
          allowAllValue: false,
          allowMultiple: false,
          plugin: {
            kind: 'StaticListVariable',
            spec: {
              values: [
                '[a-z]+|nvme[0-9]+n[0-9]+',
              ],
            },
          },
          name: 'diskdevices',
        },
      },
    ],
    annotations: [],
    duration: '1h',
    timezone: 'local',
    refreshInterval: '60s',
    datasources: {},
    links: [
      {
        name: 'Github',
        url: 'https://github.com/rfrail3/grafana-dashboards',
      },
      {
        name: 'Grafana',
        url: 'https://grafana.com/grafana/dashboards/1860',
      },
    ],
  },
}
