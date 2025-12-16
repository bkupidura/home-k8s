{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.13.2',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:06122025',
    },
    ubuntu: {
      image: 'ubuntu:noble-20251013',
    },
    kubernetes_descheduler: {
      chart: '0.33.0',
    },
    kubernetes_reflector: {
      chart: '9.1.45',
    },
    metallb: {
      chart: '0.15.3',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.15.3',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.15.3',
      },
    },
    nut: {
      image: 'instantlinux/nut-upsd:2.8.3-r3',
      metrics: 'ghcr.io/druggeri/nut_exporter:3.2.2',
    },
    longhorn: {
      chart: '1.9.1',
    },
    restic: {
      image: 'restic/restic:0.18.1',
    },
    traefik: {
      chart: '37.4.0',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.6.4',
    },
    blocky: {
      image: 'spx01/blocky:v0.28.2',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:06122025',
    },
    authelia: {
      image: 'authelia/authelia:4.39.15',
    },
    cert_manager: {
      chart: 'v1.19.2',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.19.2',
    },
    mariadb: {
      image: 'mariadb:12.1.2',
      metrics: 'prom/mysqld-exporter:v0.18.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.22',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:2.7.1',
    },
    esphome: {
      image: 'esphome/esphome:2025.11.5',
    },
    grafana: {
      image: 'grafana/grafana:12.3.0',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2025.11.3',
    },
    node_red: {
      image: 'nodered/node-red:4.1.2-22',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.10',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v9.5.21',
    },
    blackbox_exporter: {
      chart: '11.6.0',
    },
    alertmanager: {
      chart: '1.29.0',
    },
    kube_state_metrics: {
      chart: '7.0.0',
    },
    node_exporter: {
      chart: '4.49.2',
    },
    fluentbit: {
      chart: '0.54.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.27.0',
      },
      server: {
        chart: '0.26.0',
      },
      logs: {
        chart: '0.11.18',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.34.3-alpine',
    },
    nextcloud: {
      image: 'nextcloud:32.0.2-apache',
    },
    valkey: {
      image: 'valkey/valkey:9.0.1',
      metrics: 'oliver006/redis_exporter:v1.80.1',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.27.1',
    },
    registry: {
      image: 'registry:2',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.20.1',
    },
    reloader: {
      chart: '2.2.5',
    },
    democratic_csi: {
      chart: '0.15.0',
      tag: 'v1.9.3',
    },
    bazarr: {
      image: 'linuxserver/bazarr:v1.5.3-ls327',
    },
    radarr: {
      image: 'linuxserver/radarr:6.0.4',
    },
    sonarr: {
      image: 'linuxserver/sonarr:4.0.16',
    },
    nzbget: {
      image: 'nzbgetcom/nzbget:v25.4',
    },
    jellyfin: {
      image: 'jellyfin/jellyfin:10.11.4',
    },
    homer: {
      image: 'b4bz/homer:v25.11.1',
    },
    immich: {
      image: 'ghcr.io/immich-app/immich-server:v2.3.1',
      postgres: 'docker.io/tensorchord/pgvecto-rs:pg16-v0.3.0',
    },
    dmh: {
      image: 'ghcr.io/bkupidura/dead-man-hand:0.3.4',
    },
  },
}
