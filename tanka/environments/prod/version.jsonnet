{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.11.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:13072024',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20240627.1',
    },
    kubernetes_descheduler: {
      chart: '0.30.1',
    },
    kubernetes_reflector: {
      chart: '7.1.288',
    },
    metallb: {
      chart: '0.14.7',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.14.7',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.14.7',
      },
    },
    nut: {
      image: 'instantlinux/nut-upsd:2.8.2-r0',
      metrics: 'ghcr.io/druggeri/nut_exporter:3.1.1',
    },
    longhorn: {
      chart: '1.6.2',
    },
    restic: {
      image: 'restic/restic:0.16.5',
    },
    traefik: {
      chart: '29.0.1',
      repo: 'traefik',
      tag: 'v3.1.0',
    },
    blocky: {
      image: 'spx01/blocky:v0.24',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:13072024',
    },
    authelia: {
      image: 'authelia/authelia:4.38.9',
    },
    cert_manager: {
      chart: 'v1.15.1',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.15.1',
    },
    mariadb: {
      image: 'mariadb:11.4.2',
      metrics: 'prom/mysqld-exporter:v0.15.1',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.18',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.39.0',
    },
    esphome: {
      image: 'esphome/esphome:2024.7.0',
    },
    grafana: {
      image: 'grafana/grafana:11.0.1',
    },
    loki: {
      server: '6.7.1',
      fluentbit: '0.47.2',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.7.3',
    },
    node_red: {
      image: 'nodered/node-red:4.0.2-22',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.6',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v8.2.93',
    },
    prometheus: {
      chart: '25.24.1',
    },
    blackbox_exporter: {
      chart: '8.17.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.9.10',
      },
      server: {
        chart: '0.9.24',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.31.0-alpine',
    },
    nextcloud: {
      image: 'nextcloud:29.0.3-apache',
    },
    redis: {
      image: 'redis:7.2.5-alpine',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.24.1',
    },
    registry: {
      image: 'registry:2',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.11.0',
    },
  },
}
