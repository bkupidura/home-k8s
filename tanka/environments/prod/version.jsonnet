{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.12.2',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:05072025',
    },
    ubuntu: {
      image: 'ubuntu:noble-20250619',
    },
    kubernetes_descheduler: {
      chart: '0.33.0',
    },
    kubernetes_reflector: {
      chart: '9.1.20',
    },
    metallb: {
      chart: '0.15.2',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.15.2',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.15.2',
      },
    },
    nut: {
      image: 'instantlinux/nut-upsd:2.8.2-r2',
      metrics: 'ghcr.io/druggeri/nut_exporter:3.2.1',
    },
    longhorn: {
      chart: '1.8.1',
    },
    restic: {
      image: 'restic/restic:0.18.0',
      binary: 'https://github.com/restic/restic/releases/download/v0.18.0/restic_0.18.0_linux_amd64.bz2'
    },
    traefik: {
      chart: '36.3.0',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.4.3',
    },
    blocky: {
      image: 'spx01/blocky:v0.26.2',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:05072025',
    },
    authelia: {
      image: 'authelia/authelia:4.39.4',
    },
    cert_manager: {
      chart: 'v1.18.2',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.18.2',
    },
    mariadb: {
      image: 'mariadb:11.8.2',
      metrics: 'prom/mysqld-exporter:v0.17.2',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.20',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:2.5.1',
    },
    esphome: {
      image: 'esphome/esphome:2025.6.3',
    },
    grafana: {
      image: 'grafana/grafana:12.0.2',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2025.6.3',
    },
    node_red: {
      image: 'nodered/node-red:4.0.9-22',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.8',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v9.2.87',
    },
    blackbox_exporter: {
      chart: '11.0.0',
    },
    alertmanager: {
      chart: '1.22.0',
    },
    kube_state_metrics: {
      chart: '6.1.0',
    },
    node_exporter: {
      chart: '4.47.1',
    },
    fluentbit: {
      chart: '0.50.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.23.0',
      },
      server: {
        chart: '0.23.0',
      },
      logs: {
        chart: '0.11.4',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.34.1-alpine',
    },
    nextcloud: {
      image: 'nextcloud:31.0.6-apache',
    },
    valkey: {
      image: 'valkey/valkey:8.1.3',
      metrics: 'oliver006/redis_exporter:v1.74.0',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.26.3',
    },
    registry: {
      image: 'registry:2',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.17.1',
    },
    reloader: {
      chart: '2.1.5',
    },
    democratic_csi: {
      chart: '0.15.0',
      tag: 'v1.9.3',
    },
    bazarr: {
      image: 'linuxserver/bazarr:v1.5.2-ls310',
    },
    radarr: {
      image: 'linuxserver/radarr:5.26.2.10099-ls277',
    },
    sonarr: {
      image: 'linuxserver/sonarr:4.0.15.2941-ls287',
    },
    nzbget: {
      image: 'nzbgetcom/nzbget:v25.2',
    },
    jellyfin: {
      image: 'jellyfin/jellyfin:10.10.7',
    },
    homer: {
      image: 'b4bz/homer:v25.05.2',
    },
    immich: {
      image: 'ghcr.io/immich-app/immich-server:v1.135.3',
      postgres: 'docker.io/tensorchord/pgvecto-rs:pg16-v0.3.0',
      postgres_backup: 'postgresql16-client',
    },
    dmh: {
      image: 'ghcr.io/bkupidura/dead-man-hand:0.3.2',
    },
  },
}
