{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.12.0',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:16112024',
    },
    ubuntu: {
      image: 'ubuntu:noble-20241015',
    },
    kubernetes_descheduler: {
      chart: '0.30.1',
    },
    kubernetes_reflector: {
      chart: '7.1.288',
    },
    metallb: {
      chart: '0.14.8',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.14.8',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.14.8',
      },
    },
    nut: {
      image: 'instantlinux/nut-upsd:2.8.2-r0',
      metrics: 'ghcr.io/druggeri/nut_exporter:3.1.1',
    },
    longhorn: {
      chart: '1.7.2',
    },
    restic: {
      image: 'restic/restic:0.17.3',
    },
    traefik: {
      chart: '33.0.0',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.2.1',
    },
    blocky: {
      image: 'spx01/blocky:v0.24',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:16112024',
    },
    authelia: {
      image: 'authelia/authelia:4.38.17',
    },
    cert_manager: {
      chart: 'v1.16.2',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.16.2',
    },
    mariadb: {
      image: 'mariadb:11.5.2',
      metrics: 'prom/mysqld-exporter:v0.16.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.19',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.41.0',
    },
    esphome: {
      image: 'esphome/esphome:2024.11.1',
    },
    grafana: {
      image: 'grafana/grafana:11.3.1',
    },
    loki: {
      server: '6.21.0',
      fluentbit: '0.48.1',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.11.3',
    },
    node_red: {
      image: 'nodered/node-red:4.0.5-22',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.7',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v8.6.9',
    },
    prometheus: {
      chart: '25.30.1',
    },
    blackbox_exporter: {
      chart: '9.1.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.12.6',
      },
      server: {
        chart: '0.12.7',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.32.5-alpine',
    },
    nextcloud: {
      image: 'nextcloud:30.0.2-apache',
    },
    redis: {
      image: 'redis:7.4.1-alpine',
      metrics: 'oliver006/redis_exporter:v1.66.0',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.24.3',
    },
    registry: {
      image: 'registry:2',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.13.5',
    },
    reloader: {
      chart: '1.2.0',
    },
    democratic_csi: {
      chart: '0.14.7',
      image: 'democraticcsi/democratic-csi:v1.9.3',
    },
    bazarr: {
      image: 'linuxserver/bazarr:v1.4.5-ls278',
    },
    radarr: {
      image: 'linuxserver/radarr:5.15.1.9463-ls246',
    },
    sonarr: {
      image: 'linuxserver/sonarr:4.0.10.2544-ls259',
    },
    nzbget: {
      image: 'nzbgetcom/nzbget:v24.4',
    },
    jellyfin: {
      image: 'jellyfin/jellyfin:10.10.3',
    },
    prowlarr: {
      image: 'linuxserver/prowlarr:1.27.0.4852-ls93',
    },
  },
}
