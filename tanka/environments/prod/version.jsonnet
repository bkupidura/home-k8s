{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.11.3',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:07092024',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20240808',
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
      chart: '1.7.1',
    },
    restic: {
      image: 'restic/restic:0.17.1',
    },
    traefik: {
      chart: '31.0.0',
      repo: 'traefik',
      tag: 'v3.1.2',
    },
    blocky: {
      image: 'spx01/blocky:v0.24',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:07092024',
    },
    authelia: {
      image: 'authelia/authelia:4.38.10',
    },
    cert_manager: {
      chart: 'v1.15.3',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.15.3',
    },
    mariadb: {
      image: 'mariadb:11.5.2',
      metrics: 'prom/mysqld-exporter:v0.15.1',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.18',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.40.1',
    },
    esphome: {
      image: 'esphome/esphome:2024.8.3',
    },
    grafana: {
      image: 'grafana/grafana:11.2.0',
    },
    loki: {
      server: '6.12.0',
      fluentbit: '0.47.9',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.8.3',
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
      image: 'jacobalberty/unifi:v8.4.59',
    },
    prometheus: {
      chart: '25.27.0',
    },
    blackbox_exporter: {
      chart: '9.0.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.11.1',
      },
      server: {
        chart: '0.11.1',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.32.0-alpine',
    },
    nextcloud: {
      image: 'nextcloud:29.0.6-apache',
    },
    redis: {
      image: 'redis:7.4.0-alpine',
      metrics: 'oliver006/redis_exporter:v1.63.0',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.24.3',
    },
    registry: {
      image: 'registry:2',
    },
    paperless: {
      image: 'ghcr.io/paperless-ngx/paperless-ngx:2.12.0',
    },
  },
}
