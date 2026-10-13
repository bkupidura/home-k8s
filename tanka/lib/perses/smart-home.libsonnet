{
  kind: 'Dashboard',
  metadata: {
    name: 'smart-home',
    createdAt: '2026-10-10T17:33:30.156189831Z',
    updatedAt: '2026-10-10T17:33:30.156189831Z',
    version: 0,
    project: 'home-lab',
  },
  spec: {
    display: {
      name: 'Smart home',
    },
    panels: {
      '0_0': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Temperature outside',
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
                  decimalPlaces: 0,
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
                    query: 'hass_sensor_temperature_celsius{entity_name=~"(temperature_outside_temperature|openweathermap_forecast_temperature|openweathermap_temperature|netatmo_poznan_temperature)"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Temperature inside',
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
                  decimalPlaces: 1,
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
                    query: 'hass_sensor_temperature_celsius{entity_name=~"(temperature_playroom_temperature|temperature_guest_room_temperature|temperature_bedroom_temperature|temperature_living_room_temperature|temperature_office_temperature)"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Humidity outside',
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
                  decimalPlaces: 0,
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
                    query: 'hass_sensor_humidity_percent{entity_name=~"^(openweathermap_humidity|temperature_outside_humidity|netatmo_poznan_humidity)$"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Humidity inside',
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
                  decimalPlaces: 0,
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
                    query: 'hass_sensor_humidity_percent{entity_name=~"temperature_.*_humidity",entity_name!~"temperature_outside_humidity|temperature_office_vault_humidity"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Climate temperature',
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
                  decimalPlaces: 0,
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
                    query: 'hass_climate_target_temperature_celsius{domain="climate"}',
                    seriesNameFormat: '{{ entity_name }} desired',
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
                    query: 'hass_climate_current_temperature_celsius{domain="climate"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'AQI',
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
                    query: 'hass_aqi',
                    seriesNameFormat: '{{entity_name}}',
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
                    query: 'hass_sensor_pm25_u0xb5g_per_mu0xb3',
                    seriesNameFormat: 'bedroom',
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
            name: 'Mold indicator',
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
                lineStyle: 'solid',
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
                    query: 'hass_sensor_humidity_percent{entity=~".*mold.*"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Illuminance',
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
                    minStep: '',
                    query: 'hass_sensor_illuminance_lx{entity_name=~"^sun.*"}',
                    seriesNameFormat: '{{ entity }}',
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
            name: 'Motion',
          },
          plugin: {
            kind: 'StatusHistoryChart',
            spec: {
              sorting: 'desc',
              mappings: [],
            },
          },
          queries: [
            {
              kind: 'TimeSeriesQuery',
              spec: {
                plugin: {
                  kind: 'PrometheusTimeSeriesQuery',
                  spec: {
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.pir_.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
                  },
                },
              },
            },
          ],
          links: [],
        },
      },
      '1_1': {
        kind: 'Panel',
        spec: {
          display: {
            name: 'Reedswitch level 0',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_office.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_living_room.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_kitchen.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_main_door.*"} == 1 ',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Reedswitch level 1',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_guest_room.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_playroom.*"} == 1',
                    seriesNameFormat: '{{ entity_name }} ',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_bedroom.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_binary_sensor_state{entity=~"binary_sensor.redswitch_hallway.*"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Presence',
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
                    query: 'hass_person_state == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_input_boolean_state{entity="input_boolean.occupancy"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_input_boolean_state{entity="input_boolean.guest"} == 1',
                    seriesNameFormat: '{{ entity_name }}',
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
                    query: 'hass_input_boolean_state{entity="input_boolean.guest_occupancy"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Sleeping',
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
                    minStep: '',
                    query: 'hass_binary_sensor_state{entity_name="bayes_sleeping"}',
                    seriesNameFormat: '{{ entity }}',
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
                    query: 'hass_input_boolean_state{entity_name="sleeping"}',
                    seriesNameFormat: '{{ entity }}',
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
                    query: 'hass_binary_sensor_state{entity_name="day"}',
                    seriesNameFormat: '{{ entity }}',
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
                    query: 'hass_binary_sensor_state{entity_name="morning"}',
                    seriesNameFormat: '{{ entity }}',
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
            name: 'Unavailable sensor',
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
                  decimalPlaces: 0,
                  unit: 'decimal',
                },
                min: 0,
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
                    query: 'hass_sensor_state{entity_name="unavailable_sensor"}',
                    seriesNameFormat: '{{ entity_name }}',
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
            name: 'Low battery percent',
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
                max: 100,
                min: 0,
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
                    query: '0 < hass_sensor_battery_percent{entity_name!~"^iphone_.*"} < 35',
                    seriesNameFormat: '{{ entity_name }}',
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
            title: 'Environment',
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
                '$ref': '#/spec/panels/0_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_1',
              },
            },
            {
              x: 0,
              y: 8,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_2',
              },
            },
            {
              x: 12,
              y: 8,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_3',
              },
            },
            {
              x: 0,
              y: 16,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_4',
              },
            },
            {
              x: 12,
              y: 16,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_5',
              },
            },
            {
              x: 0,
              y: 24,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_6',
              },
            },
            {
              x: 12,
              y: 24,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/0_7',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Security',
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
              width: 24,
              height: 12,
              content: {
                '$ref': '#/spec/panels/1_1',
              },
            },
            {
              x: 0,
              y: 19,
              width: 24,
              height: 12,
              content: {
                '$ref': '#/spec/panels/1_2',
              },
            },
            {
              x: 0,
              y: 31,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_3',
              },
            },
            {
              x: 12,
              y: 31,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/1_4',
              },
            },
          ],
        },
      },
      {
        kind: 'Grid',
        spec: {
          display: {
            title: 'Infra',
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
                '$ref': '#/spec/panels/2_0',
              },
            },
            {
              x: 12,
              y: 0,
              width: 12,
              height: 8,
              content: {
                '$ref': '#/spec/panels/2_1',
              },
            },
          ],
        },
      },
    ],
    variables: [],
    annotations: [],
    duration: '6h',
    timezone: 'local',
    refreshInterval: '60s',
    datasources: {},
    links: [],
  },
}
