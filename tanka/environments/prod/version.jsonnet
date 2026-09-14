{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.14.7',
    },
    chrony: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/chrony:29082026',
          destination: std.format('registry.%s/chrony:29082026', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/chrony:29082026', std.extVar('secrets').domain),
    },
    ubuntu: {
      cache: [
        {
          source: 'ubuntu:noble-20260810',
          destination: std.format('registry.%s/ubuntu:noble-20260810', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/ubuntu:noble-20260810', std.extVar('secrets').domain),
    },
    kubernetes_descheduler: {
      chart: '0.36.0',
    },
    kubernetes_reflector: {
      chart: '10.0.65',
    },
    nut: {
      cache: [
        {
          source: 'instantlinux/nut-upsd:2.8.5-r1',
          destination: std.format('registry.%s/nut-upsd:2.8.5-r1', std.extVar('secrets').domain),
        },
        {
          source: 'ghcr.io/druggeri/nut_exporter:3.3.0',
          destination: std.format('registry.%s/nut-exporter:3.3.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nut-upsd:2.8.5-r1', std.extVar('secrets').domain),
      metrics: std.format('registry.%s/nut-exporter:3.3.0', std.extVar('secrets').domain),
    },
    longhorn: {
      chart: '1.12.1',
    },
    restic: {
      image: 'restic/restic:0.19.1',
    },
    traefik: {
      chart: '41.4.0',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.7.12',
    },
    blocky: {
      cache: [
        {
          source: 'spx01/blocky:v0.34.0',
          destination: std.format('registry.%s/blocky:v0.34.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/blocky:v0.34.0', std.extVar('secrets').domain),
    },
    waf: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/waf-modsecurity:29082026',
          destination: std.format('registry.%s/waf-modsecurity:29082026', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/waf-modsecurity:29082026', std.extVar('secrets').domain),
    },
    authelia: {
      cache: [
        {
          source: 'authelia/authelia:4.39.22',
          destination: std.format('registry.%s/authelia:4.39.22', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/authelia:4.39.22', std.extVar('secrets').domain),
    },
    cert_manager: {
      chart: 'v1.21.1',
      image: 'quay.io/jetstack/cert-manager-controller:v1.21.1',
    },
    mariadb: {
      cache: [
        {
          source: 'mariadb:12.3.3',
          destination: std.format('registry.%s/mariadb:12.3.3', std.extVar('secrets').domain),
        },
        {
          source: 'prom/mysqld-exporter:v0.20.0',
          destination: std.format('registry.%s/mysqld-exporter:v0.20.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/mariadb:12.3.3', std.extVar('secrets').domain),
      metrics: std.format('registry.%s/mysqld-exporter:v0.20.0', std.extVar('secrets').domain),
    },
    broker_ha: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/broker-ha:0.1.23',
          destination: std.format('registry.%s/broker-ha:0.1.23', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/broker-ha:0.1.23', std.extVar('secrets').domain),
    },
    zigbee2mqtt: {
      cache: [
        {
          source: 'koenkk/zigbee2mqtt:2.14.0',
          destination: std.format('registry.%s/zigbee2mqtt:2.14.0', std.extVar('secrets').domain),
        },
        {
          source: 'ghcr.io/deconz-community/deconz-docker:2.33.2',
          destination: std.format('registry.%s/deconz-docker:2.33.2', std.extVar('secrets').domain),
        },
      ],
      deconz: std.format('registry.%s/deconz-docker:2.33.2', std.extVar('secrets').domain),
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: std.format('registry.%s/zigbee2mqtt:2.14.0', std.extVar('secrets').domain),
    },
    esphome: {
      cache: [
        {
          source: 'esphome/esphome:2026.8.2',
          destination: std.format('registry.%s/esphome:2026.8.2', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/esphome:2026.8.2', std.extVar('secrets').domain),
    },
    grafana: {
      cache: [
        {
          source: 'grafana/grafana:13.2.1',
          destination: std.format('registry.%s/grafana:13.2.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/grafana:13.2.1', std.extVar('secrets').domain),
    },
    home_assistant: {
      cache: [
        {
          source: 'homeassistant/home-assistant:2026.8.3',
          destination: std.format('registry.%s/home-assistant:2026.8.3', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/home-assistant:2026.8.3', std.extVar('secrets').domain),
    },
    node_red: {
      cache: [
        {
          source: 'nodered/node-red:5.0.6',
          destination: std.format('registry.%s/node-red:5.0.6', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/node-red:5.0.6', std.extVar('secrets').domain),
    },
    recorder: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/recorder:2.0.11',
          destination: std.format('registry.%s/recorder:2.0.11', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/recorder:2.0.11', std.extVar('secrets').domain),
    },
    sms_gammu: {
      cache: [
        {
          source: 'bnutzer/sms-gammu-gateway:sha-db9a0b2',
          destination: std.format('registry.%s/sms-gammu-gateway:sha-db9a0b2', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/sms-gammu-gateway:sha-db9a0b2', std.extVar('secrets').domain),
    },
    unifi: {
      cache: [
        {
          source: 'jacobalberty/unifi:v10.0.162',
          destination: std.format('registry.%s/unifi:v10.0.162', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/unifi:v10.0.162', std.extVar('secrets').domain),
    },
    blackbox_exporter: {
      cache: [
        {
          source: 'quay.io/prometheus/blackbox-exporter:v0.28.0',
          destination: std.format('registry.%s/blackbox-exporter:v0.28.0', std.extVar('secrets').domain),
        },
      ],
      chart: '11.18.0',
      registry: std.format('registry.%s', std.extVar('secrets').domain),
      repository: 'blackbox-exporter',
      tag: 'v0.28.0',
    },
    alertmanager: {
      cache: [
        {
          source: 'quay.io/prometheus/alertmanager:v0.34.0',
          destination: std.format('registry.%s/alertmanager:v0.34.0', std.extVar('secrets').domain),
        },
        {
          source: 'quay.io/prometheus-operator/prometheus-config-reloader:v0.93.1',
          destination: std.format('registry.%s/prometheus-config-reloader:v0.93.1', std.extVar('secrets').domain),
        },
      ],
      chart: '1.42.0',
      image: std.format('registry.%s/alertmanager:v0.34.0', std.extVar('secrets').domain),
      reloader: std.format('registry.%s/prometheus-config-reloader:v0.93.1', std.extVar('secrets').domain),
    },
    kube_state_metrics: {
      cache: [
        {
          source: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.20.0',
          destination: std.format('registry.%s/kube-state-metrics:v2.20.0', std.extVar('secrets').domain),
        },
      ],
      chart: '8.4.1',
      registry: std.format('registry.%s', std.extVar('secrets').domain),
      repository: 'kube-state-metrics',
      tag: 'v2.20.0',
    },
    node_exporter: {
      cache: [
        {
          source: 'quay.io/prometheus/node-exporter:v1.12.1',
          destination: std.format('registry.%s/node-exporter:v1.12.1', std.extVar('secrets').domain),
        },
      ],
      chart: '4.56.3',
      registry: std.format('registry.%s', std.extVar('secrets').domain),
      repository: 'node-exporter',
      tag: 'v1.12.1',
    },
    fluentbit: {
      cache: [
        {
          source: 'cr.fluentbit.io/fluent/fluent-bit:5.1.1',
          destination: std.format('registry.%s/fluent-bit:5.1.1', std.extVar('secrets').domain),
        },
      ],
      chart: '0.58.1',
      image: std.format('registry.%s/fluent-bit:5.1.1', std.extVar('secrets').domain),
    },
    victoria_metrics: {
      cache: [
        {
          source: 'victoriametrics/vmalert:v1.150.0',
          destination: std.format('registry.%s/vmalert:v1.150.0', std.extVar('secrets').domain),
        },
        {
          source: 'victoriametrics/victoria-metrics:v1.150.0',
          destination: std.format('registry.%s/victoria-metrics:v1.150.0', std.extVar('secrets').domain),
        },
        {
          source: 'victoriametrics/victoria-logs:v1.52.0',
          destination: std.format('registry.%s/victoria-logs:v1.52.0', std.extVar('secrets').domain),
        },
      ],
      alert: {
        chart: '0.47.0',
        registry: std.format('registry.%s', std.extVar('secrets').domain),
        repository: 'vmalert',
        tag: 'v1.150.0',
      },
      server: {
        chart: '0.45.0',
        registry: std.format('registry.%s', std.extVar('secrets').domain),
        repository: 'victoria-metrics',
        tag: 'v1.150.0',
      },
      logs: {
        chart: '0.13.9',
        registry: std.format('registry.%s', std.extVar('secrets').domain),
        repository: 'victoria-logs',
        tag: 'v1.52.0',
      },
    },
    vaultwarden: {
      cache: [
        {
          source: 'vaultwarden/server:1.37.2-alpine',
          destination: std.format('registry.%s/vaultwarden:1.37.2-alpine', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/vaultwarden:1.37.2-alpine', std.extVar('secrets').domain),
    },
    nextcloud: {
      cache: [
        {
          source: 'nextcloud:34.0.3-apache',
          destination: std.format('registry.%s/nextcloud:34.0.3-apache', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nextcloud:34.0.3-apache', std.extVar('secrets').domain),
    },
    valkey: {
      cache: [
        {
          source: 'valkey/valkey:9.1.2',
          destination: std.format('registry.%s/valkey:9.1.2', std.extVar('secrets').domain),
        },
        {
          source: 'oliver006/redis_exporter:v1.90.0',
          destination: std.format('registry.%s/redis_exporter:v1.90.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/valkey:9.1.2', std.extVar('secrets').domain),
      metrics: std.format('registry.%s/redis_exporter:v1.90.0', std.extVar('secrets').domain),
    },
    freshrss: {
      cache: [
        {
          source: 'freshrss/freshrss:1.29.1',
          destination: std.format('registry.%s/freshrss:1.29.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/freshrss:1.29.1', std.extVar('secrets').domain),
    },
    registry: {
      image: 'registry:3.1.1',
    },
    paperless: {
      cache: [
        {
          source: 'ghcr.io/paperless-ngx/paperless-ngx:3.1.2',
          destination: std.format('registry.%s/paperless-ngx:3.1.2', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/paperless-ngx:3.1.2', std.extVar('secrets').domain),
    },
    reloader: {
      chart: '2.2.16',
    },
    democratic_csi: {
      cache: [
        {
          source: 'docker.io/democraticcsi/democratic-csi:v1.9.5',
          destination: std.format('registry.%s/democratic-csi:v1.9.5', std.extVar('secrets').domain),
        },
      ],
      chart: '0.15.1',
      image: std.format('registry.%s/democratic-csi:v1.9.5', std.extVar('secrets').domain),
    },
    bazarr: {
      cache: [
        {
          source: 'linuxserver/bazarr:1.6.0',
          destination: std.format('registry.%s/bazarr:1.6.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/bazarr:1.6.0', std.extVar('secrets').domain),
    },
    radarr: {
      cache: [
        {
          source: 'linuxserver/radarr:6.3.0',
          destination: std.format('registry.%s/radarr:6.3.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/radarr:6.3.0', std.extVar('secrets').domain),
    },
    sonarr: {
      cache: [
        {
          source: 'linuxserver/sonarr:4.0.19',
          destination: std.format('registry.%s/sonarr:4.0.19', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/sonarr:4.0.19', std.extVar('secrets').domain),
    },
    nzbget: {
      cache: [
        {
          source: 'nzbgetcom/nzbget:v26.3',
          destination: std.format('registry.%s/nzbget:v26.3', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nzbget:v26.3', std.extVar('secrets').domain),
    },
    jellyfin: {
      cache: [
        {
          source: 'jellyfin/jellyfin:10.11.11',
          destination: std.format('registry.%s/jellyfin:10.11.11', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/jellyfin:10.11.11', std.extVar('secrets').domain),
    },
    homer: {
      cache: [
        {
          source: 'b4bz/homer:v26.08.3',
          destination: std.format('registry.%s/homer:v26.08.3', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/homer:v26.08.3', std.extVar('secrets').domain),
    },
    immich: {
      cache: [
        {
          source: 'ghcr.io/immich-app/immich-server:v3.1.0',
          destination: std.format('registry.%s/immich-server:v3.1.0', std.extVar('secrets').domain),
        },
        {
          source: 'ghcr.io/immich-app/postgres:16-vectorchord1.1.1',
          destination: std.format('registry.%s/immich-postgres:16-vectorchord1.1.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/immich-server:v3.1.0', std.extVar('secrets').domain),
      postgres: std.format('registry.%s/immich-postgres:16-vectorchord1.1.1', std.extVar('secrets').domain),
    },
    dmh: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/dead-man-hand:0.4.1',
          destination: std.format('registry.%s/dead-man-hand:0.4.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/dead-man-hand:0.4.1', std.extVar('secrets').domain),
    },
    nfc2mqtt: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/nfc2mqtt:0.1.7',
          destination: std.format('registry.%s/nfc2mqtt:0.1.7', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nfc2mqtt:0.1.7', std.extVar('secrets').domain),
    },
    mealie: {
      cache: [
        {
          source: 'ghcr.io/mealie-recipes/mealie:v3.25.0',
          destination: std.format('registry.%s/mealie:v3.25.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/mealie:v3.25.0', std.extVar('secrets').domain),
    },
    generic_device_plugin: {
      cache: [
        {
          source: 'squat/generic-device-plugin:0.2.0',
          destination: std.format('registry.%s/generic-device-plugin:0.2.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/generic-device-plugin:0.2.0', std.extVar('secrets').domain),
    },
  },
}
