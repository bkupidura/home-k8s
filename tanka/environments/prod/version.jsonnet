{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.12.0',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:22032025',
    },
    ubuntu: {
      image: 'ubuntu:noble-20250127',
    },
    kubernetes_descheduler: {
      chart: '0.33.0',
    },
    kubernetes_reflector: {
      chart: '9.0.322',
    },
    metallb: {
      chart: '0.14.9',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.14.9',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.14.9',
      },
    },
    nut: {
      image: 'instantlinux/nut-upsd:2.8.2-r2',
      metrics: 'ghcr.io/druggeri/nut_exporter:3.1.3',
    },
    longhorn: {
      chart: '1.8.1',
    },
    restic: {
      image: 'restic/restic:0.17.3',
      binary: 'https://github.com/restic/restic/releases/download/v0.17.3/restic_0.17.3_linux_amd64.bz2',
    },
    traefik: {
      chart: '34.4.1',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.3.4',
    },
    blocky: {
      image: 'spx01/blocky:v0.25',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:22032025',
    },
    authelia: {
      image: 'authelia/authelia:4.39.1',
    },
    cert_manager: {
      chart: 'v1.17.1',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.17.1',
    },
    mariadb: {
      image: 'mariadb:11.7.2',
      metrics: 'prom/mysqld-exporter:v0.17.2',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.20',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:2.1.3',
    },
    esphome: {
      image: 'esphome/esphome:2025.3.1',
    },
    grafana: {
      image: 'grafana/grafana:11.6.0',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2025.3.4',
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
      image: 'jacobalberty/unifi:v9.0.114',
    },
    blackbox_exporter: {
      chart: '9.4.0',
    },
    alertmanager: {
      chart: '1.16.0',
    },
    kube_state_metrics: {
      chart: '5.31.0',
    },
    node_exporter: {
      chart: '4.45.0',
    },
    fluentbit: {
      chart: '0.48.9',
    },
    victoria_metrics: {
      alert: {
        chart: '0.15.0',
      },
      server: {
        chart: '0.15.1',
      },
      logs: {
        chart: '0.9.8',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.33.2-alpine',
    },
    nextcloud: {
      image: 'nextcloud:31.0.2-apache',
    },
    valkey: {
      image: 'valkey/valkey:8.0.2',
      metrics: 'oliver006/redis_exporter:v1.69.0',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.26.1',
    },
    registry: {
      image: 'registry:2',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.14.7',
    },
    reloader: {
      chart: '1.3.0',
    },
    democratic_csi: {
      chart: '0.14.7',
      image: 'democraticcsi/democratic-csi:v1.9.3',
    },
    bazarr: {
      image: 'linuxserver/bazarr:v1.5.1-ls296',
    },
    radarr: {
      image: 'linuxserver/radarr:5.19.3.9730-ls262',
    },
    sonarr: {
      image: 'linuxserver/sonarr:4.0.14.2939-ls275',
    },
    nzbget: {
      image: 'nzbgetcom/nzbget:v24.6',
    },
    jellyfin: {
      image: 'jellyfin/jellyfin:10.10.6',
    },
    homer: {
      image: 'b4bz/homer:v25.03.3',
    },
    immich: {
      image: 'ghcr.io/immich-app/immich-server:v1.129.0',
      postgres: 'docker.io/tensorchord/pgvecto-rs:pg16-v0.3.0',
      postgres_backup: 'postgresql16-client',
    },
    dmh: {
      image: 'ghcr.io/bkupidura/dead-man-hand:0.3.2',
    },
  },
}
