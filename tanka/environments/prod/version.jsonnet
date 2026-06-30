{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.14.4',
    },
    chrony: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/chrony:13062026',
          destination: std.format('registry.%s/chrony:13062026', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/chrony:13062026', std.extVar('secrets').domain),
    },
    ubuntu: {
      cache: [
        {
          source: 'ubuntu:noble-20260509.1',
          destination: std.format('registry.%s/ubuntu:noble-20260509.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/ubuntu:noble-20260509.1', std.extVar('secrets').domain),
    },
    kubernetes_descheduler: {
      chart: '0.35.1',
    },
    kubernetes_reflector: {
      chart: '10.0.49',
    },
    metallb: {
      chart: '0.16.1',
      controller: 'quay.io/metallb/controller:v0.16.1',
      speaker: 'quay.io/metallb/speaker:v0.16.1',
    },
    nut: {
      cache: [
        {
          source: 'instantlinux/nut-upsd:2.8.3-r4',
          destination: std.format('registry.%s/nut-upsd:2.8.3-r4', std.extVar('secrets').domain),
        },
        {
          source: 'ghcr.io/druggeri/nut_exporter:3.3.0',
          destination: std.format('registry.%s/nut-exporter:3.3.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nut-upsd:2.8.3-r4', std.extVar('secrets').domain),
      metrics: std.format('registry.%s/nut-exporter:3.3.0', std.extVar('secrets').domain),
    },
    longhorn: {  // todo
      chart: '1.11.1',
    },
    restic: {
      image: 'restic/restic:0.19.0',
    },
    traefik: {
      chart: '40.3.0',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.7.4',
    },
    blocky: {
      cache: [
        {
          source: 'spx01/blocky:v0.31.0',
          destination: std.format('registry.%s/blocky:v0.31.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/blocky:v0.31.0', std.extVar('secrets').domain),
    },
    waf: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/waf-modsecurity:13062026',
          destination: std.format('registry.%s/waf-modsecurity:13062026', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/waf-modsecurity:13062026', std.extVar('secrets').domain),
    },
    authelia: {
      cache: [
        {
          source: 'authelia/authelia:4.39.20',
          destination: std.format('registry.%s/authelia:4.39.20', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/authelia:4.39.20', std.extVar('secrets').domain),
    },
    cert_manager: {
      chart: 'v1.20.2',
      image: 'quay.io/jetstack/cert-manager-controller:v1.20.2',
    },
    mariadb: {
      cache: [
        {
          source: 'mariadb:12.3.2',
          destination: std.format('registry.%s/mariadb:12.3.2', std.extVar('secrets').domain),
        },
        {
          source: 'prom/mysqld-exporter:v0.19.0',
          destination: std.format('registry.%s/mysqld-exporter:v0.19.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/mariadb:12.3.2', std.extVar('secrets').domain),
      metrics: std.format('registry.%s/mysqld-exporter:v0.19.0', std.extVar('secrets').domain),
    },
    broker_ha: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/broker-ha:0.1.22',
          destination: std.format('registry.%s/broker-ha:0.1.22', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/broker-ha:0.1.22', std.extVar('secrets').domain),
    },
    zigbee2mqtt: {
      cache: [
        {
          source: 'koenkk/zigbee2mqtt:2.12.0',
          destination: std.format('registry.%s/zigbee2mqtt:2.12.0', std.extVar('secrets').domain),
        },
        {
          source: 'ghcr.io/deconz-community/deconz-docker:2.33.0',
          destination: std.format('registry.%s/deconz-docker:2.33.0', std.extVar('secrets').domain),
        },
      ],
      deconz: std.format('registry.%s/deconz-docker:2.33.0', std.extVar('secrets').domain),
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: std.format('registry.%s/zigbee2mqtt:2.12.0', std.extVar('secrets').domain),
    },
    esphome: {
      cache: [
        {
          source: 'esphome/esphome:2026.5.3',
          destination: std.format('registry.%s/esphome:2026.5.3', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/esphome:2026.5.3', std.extVar('secrets').domain),
    },
    grafana: {
      cache: [
        {
          source: 'grafana/grafana:13.0.2',
          destination: std.format('registry.%s/grafana:13.0.2', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/grafana:13.0.2', std.extVar('secrets').domain),
    },
    home_assistant: {
      cache: [
        {
          source: 'homeassistant/home-assistant:2026.6.3',
          destination: std.format('registry.%s/home-assistant:2026.6.3', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/home-assistant:2026.6.3', std.extVar('secrets').domain),
    },
    node_red: {
      cache: [
        {
          source: 'nodered/node-red:5.0.0',
          destination: std.format('registry.%s/node-red:5.0.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/node-red:5.0.0', std.extVar('secrets').domain),
    },
    recorder: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/recorder:2.0.10',
          destination: std.format('registry.%s/recorder:2.0.10', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/recorder:2.0.10', std.extVar('secrets').domain),
    },
    sms_gammu: {
      cache: [
        {
          source: 'pajikos/sms-gammu-gateway:1.3.0',
          destination: std.format('registry.%s/sms-gammu-gateway:1.3.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/sms-gammu-gateway:1.3.0', std.extVar('secrets').domain),
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
      chart: '11.12.0',
      registry: std.format('registry.%s', std.extVar('secrets').domain),
      repository: 'blackbox-exporter',
      tag: 'v0.28.0',
    },
    alertmanager: {
      cache: [
        {
          source: 'quay.io/prometheus/alertmanager:v0.33.0',
          destination: std.format('registry.%s/alertmanager:v0.33.0', std.extVar('secrets').domain),
        },
        {
          source: 'quay.io/prometheus-operator/prometheus-config-reloader:v0.91.0',
          destination: std.format('registry.%s/prometheus-config-reloader:v0.91.0', std.extVar('secrets').domain),
        },
      ],
      chart: '1.39.0',
      image: std.format('registry.%s/alertmanager:v0.33.0', std.extVar('secrets').domain),
      reloader: std.format('registry.%s/prometheus-config-reloader:v0.91.0', std.extVar('secrets').domain),
    },
    kube_state_metrics: {
      cache: [
        {
          source: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.19.1',
          destination: std.format('registry.%s/kube-state-metrics:v2.19.1', std.extVar('secrets').domain),
        },
      ],
      chart: '7.5.1',
      registry: std.format('registry.%s', std.extVar('secrets').domain),
      repository: 'kube-state-metrics',
      tag: 'v2.19.1',
    },
    node_exporter: {
      cache: [
        {
          source: 'quay.io/prometheus/node-exporter:v1.11.1',
          destination: std.format('registry.%s/node-exporter:v1.11.1', std.extVar('secrets').domain),
        },
      ],
      chart: '4.55.0',
      registry: std.format('registry.%s', std.extVar('secrets').domain),
      repository: 'node-exporter',
      tag: 'v1.11.1',
    },
    fluentbit: {
      cache: [
        {
          source: 'cr.fluentbit.io/fluent/fluent-bit:5.0.7',
          destination: std.format('registry.%s/fluent-bit:5.0.7', std.extVar('secrets').domain),
        },
      ],
      chart: '0.57.7',
      image: std.format('registry.%s/fluent-bit:5.0.7', std.extVar('secrets').domain),
    },
    victoria_metrics: {
      cache: [
        {
          source: 'victoriametrics/vmalert:v1.145.0',
          destination: std.format('registry.%s/vmalert:v1.145.0', std.extVar('secrets').domain),
        },
        {
          source: 'victoriametrics/victoria-metrics:v1.145.0',
          destination: std.format('registry.%s/victoria-metrics:v1.145.0', std.extVar('secrets').domain),
        },
        {
          source: 'victoriametrics/victoria-logs:v1.50.0',
          destination: std.format('registry.%s/victoria-logs:v1.50.0', std.extVar('secrets').domain),
        },
      ],
      alert: {
        chart: '0.42.1',
        registry: std.format('registry.%s', std.extVar('secrets').domain),
        repository: 'vmalert',
        tag: 'v1.145.0',
      },
      server: {
        chart: '0.40.1',
        registry: std.format('registry.%s', std.extVar('secrets').domain),
        repository: 'victoria-metrics',
        tag: 'v1.145.0',
      },
      logs: {
        chart: '0.13.7',
        registry: std.format('registry.%s', std.extVar('secrets').domain),
        repository: 'victoria-logs',
        tag: 'v1.50.0',
      },
    },
    vaultwarden: {
      cache: [
        {
          source: 'vaultwarden/server:1.36.0-alpine',
          destination: std.format('registry.%s/vaultwarden:1.36.0-alpine', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/vaultwarden:1.36.0-alpine', std.extVar('secrets').domain),
    },
    nextcloud: {
      cache: [
        {
          source: 'nextcloud:34.0.0-apache',
          destination: std.format('registry.%s/nextcloud:34.0.0-apache', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nextcloud:34.0.0-apache', std.extVar('secrets').domain),
    },
    valkey: {
      cache: [
        {
          source: 'valkey/valkey:9.1.0',
          destination: std.format('registry.%s/valkey:9.1.0', std.extVar('secrets').domain),
        },
        {
          source: 'oliver006/redis_exporter:v1.86.0',
          destination: std.format('registry.%s/redis_exporter:v1.86.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/valkey:9.1.0', std.extVar('secrets').domain),
      metrics: std.format('registry.%s/redis_exporter:v1.86.0', std.extVar('secrets').domain),
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
      image: 'registry:3.1',
    },
    paperless: {
      cache: [
        {
          source: 'ghcr.io/paperless-ngx/paperless-ngx:2.20.15',
          destination: std.format('registry.%s/paperless-ngx:2.20.15', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/paperless-ngx:2.20.15', std.extVar('secrets').domain),
    },
    reloader: {
      chart: '2.2.12',
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
          source: 'linuxserver/bazarr:1.5.6',
          destination: std.format('registry.%s/bazarr:1.5.6', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/bazarr:1.5.6', std.extVar('secrets').domain),
    },
    radarr: {
      cache: [
        {
          source: 'linuxserver/radarr:6.2.1',
          destination: std.format('registry.%s/radarr:6.2.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/radarr:6.2.1', std.extVar('secrets').domain),
    },
    sonarr: {
      cache: [
        {
          source: 'linuxserver/sonarr:4.0.17',
          destination: std.format('registry.%s/sonarr:4.0.17', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/sonarr:4.0.17', std.extVar('secrets').domain),
    },
    nzbget: {
      cache: [
        {
          source: 'nzbgetcom/nzbget:v26.1',
          destination: std.format('registry.%s/nzbget:v26.1', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/nzbget:v26.1', std.extVar('secrets').domain),
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
          source: 'b4bz/homer:v26.4.2',
          destination: std.format('registry.%s/homer:v26.4.2', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/homer:v26.4.2', std.extVar('secrets').domain),
    },
    immich: {
      cache: [
        {
          source: 'ghcr.io/immich-app/immich-server:v2.7.5',
          destination: std.format('registry.%s/immich-server:v2.7.5', std.extVar('secrets').domain),
        },
        {
          source: 'docker.io/tensorchord/pgvecto-rs:pg16-v0.4.0',
          destination: std.format('registry.%s/pgvecto-rs:pg16-v0.4.0', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/immich-server:v2.7.5', std.extVar('secrets').domain),
      postgres: std.format('registry.%s/pgvecto-rs:pg16-v0.4.0', std.extVar('secrets').domain),
    },
    dmh: {
      cache: [
        {
          source: 'ghcr.io/bkupidura/dead-man-hand:0.3.4',
          destination: std.format('registry.%s/dead-man-hand:0.3.4', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/dead-man-hand:0.3.4', std.extVar('secrets').domain),
    },
    generic_device_plugin: {
      cache: [
        {
          source: 'squat/generic-device-plugin:a3d6f47',
          destination: std.format('registry.%s/generic-device-plugin:a3d6f47', std.extVar('secrets').domain),
        },
      ],
      image: std.format('registry.%s/generic-device-plugin:a3d6f47', std.extVar('secrets').domain),
    },
  },
}
