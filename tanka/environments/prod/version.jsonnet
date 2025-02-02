{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.12.0',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:28122024',
    },
    ubuntu: {
      image: 'ubuntu:noble-20241118.1',
    },
    kubernetes_descheduler: {
      chart: '0.30.1',
    },
    kubernetes_reflector: {
      chart: '7.1.288',
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
      metrics: 'ghcr.io/druggeri/nut_exporter:3.1.1',
    },
    longhorn: {
      chart: '1.7.2',
    },
    restic: {
      image: 'restic/restic:0.17.3',
    },
    traefik: {
      chart: '33.2.1',
      registry: 'docker.io',
      repo: 'traefik',
      tag: 'v3.2.3',
    },
    blocky: {
      image: 'spx01/blocky:v0.24',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:29012025',
    },
    authelia: {
      image: 'authelia/authelia:4.38.18',
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
      image: 'koenkk/zigbee2mqtt:1.42.0',
    },
    esphome: {
      image: 'esphome/esphome:2024.12.2',
    },
    grafana: {
      image: 'grafana/grafana:11.4.0',
    },
    loki: {
      server: '6.24.0',
      fluentbit: '0.48.4',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.12.5',
    },
    node_red: {
      image: 'nodered/node-red:4.0.8-22',
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
    blackbox_exporter: {
      chart: '9.1.0',
    },
    alertmanager: {
      chart: '1.13.1',
    },
    kube_state_metrics: {
      chart: '5.28.0',
    },
    node_exporter: {
      chart: '4.43.1',
    },
    victoria_metrics: {
      alert: {
        chart: '0.13.4',
      },
      server: {
        chart: '0.13.3',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.33.0-alpine',
    },
    nextcloud: {
      image: 'nextcloud:30.0.4-apache',
    },
    valkey: {
      image: 'valkey/valkey:8.0.1',
      metrics: 'oliver006/redis_exporter:v1.67.0',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.25.0',
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
      image: 'linuxserver/bazarr:v1.5.1-ls286',
    },
    radarr: {
      image: 'linuxserver/radarr:5.16.3.9541-ls252',
    },
    sonarr: {
      image: 'linuxserver/sonarr:4.0.11.2680-ls263',
    },
    nzbget: {
      image: 'nzbgetcom/nzbget:v24.5',
    },
    jellyfin: {
      image: 'jellyfin/jellyfin:10.10.3',
    },
    prowlarr: {
      image: 'linuxserver/prowlarr:1.28.2.4885-ls98',
    },
    homer: {
      image: 'b4bz/homer:v24.12.1',
    },
  },
}
