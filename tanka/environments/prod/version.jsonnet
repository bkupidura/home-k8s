{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.14.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:31012026',
    },
    ubuntu: {
      image: 'ubuntu:noble-20260113',
    },
    kubernetes_descheduler: {
      chart: '0.33.0',
    },
    kubernetes_reflector: {
      chart: '10.0.4',
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
      metrics: 'ghcr.io/druggeri/nut_exporter:3.2.3',
    },
    longhorn: {
      chart: '1.11.0',
    },
    restic: {
      image: 'restic/restic:0.18.1',
    },
    traefik: {
      chart: '39.0.0',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.6.7',
    },
    blocky: {
      image: 'spx01/blocky:v0.28.2',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:31012026',
    },
    authelia: {
      image: 'authelia/authelia:4.39.15',
    },
    cert_manager: {
      chart: 'v1.19.3',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.19.3',
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
      image: 'koenkk/zigbee2mqtt:2.8.0',
    },
    esphome: {
      image: 'esphome/esphome:2026.1.4',
    },
    grafana: {
      image: 'grafana/grafana:12.3.2',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2026.1.3',
    },
    node_red: {
      image: 'nodered/node-red:4.1.4-22',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.10',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v10.0.162',
    },
    blackbox_exporter: {
      chart: '11.7.1',
    },
    alertmanager: {
      chart: '1.32.0',
    },
    kube_state_metrics: {
      chart: '7.1.0',
    },
    node_exporter: {
      chart: '4.51.1',
    },
    fluentbit: {
      chart: '0.55.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.31.0',
      },
      server: {
        chart: '0.30.0',
      },
      logs: {
        chart: '0.11.25',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.35.2-alpine',
    },
    nextcloud: {
      image: 'nextcloud:32.0.5-apache',
    },
    valkey: {
      image: 'valkey/valkey:9.0.2',
      metrics: 'oliver006/redis_exporter:v1.80.2',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.28.1',
    },
    registry: {
      image: 'registry:3',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.20.6',
    },
    reloader: {
      chart: '2.2.7',
    },
    democratic_csi: {
      chart: '0.15.1',
      tag: 'v1.9.5',
    },
    bazarr: {
      image: 'linuxserver/bazarr:1.5.5',
    },
    radarr: {
      image: 'linuxserver/radarr:6.0.4',
    },
    sonarr: {
      image: 'linuxserver/sonarr:4.0.16',
    },
    nzbget: {
      image: 'nzbgetcom/nzbget:v26.0',
    },
    jellyfin: {
      image: 'jellyfin/jellyfin:10.11.6',
    },
    homer: {
      image: 'b4bz/homer:v25.11.1',
    },
    immich: {
      image: 'ghcr.io/immich-app/immich-server:v2.5.5',
      postgres: 'docker.io/tensorchord/pgvecto-rs:pg16-v0.3.0',
    },
    dmh: {
      image: 'ghcr.io/bkupidura/dead-man-hand:0.3.4',
    },
  },
}
