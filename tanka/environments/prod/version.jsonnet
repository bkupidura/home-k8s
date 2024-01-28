{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.11.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:20012024',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20240111',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.29.0',
    },
    kubernetes_reflector: {
      chart: '7.1.238',
    },
    metallb: {
      chart: '0.13.12',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.13.12',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.13.12',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.8.0',
    },
    longhorn: {
      chart: '1.5.3',
    },
    restic: {
      image: 'restic/restic:0.16.3',
    },
    traefik: {
      chart: '26.0.0',
      repo: 'traefik',
      tag: 'v2.10.7',
    },
    blocky: {
      image: 'spx01/blocky:v0.23',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:20012024',
    },
    authelia: {
      image: 'authelia/authelia:4.37.5',
    },
    cert_manager: {
      chart: 'v1.13.3',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.13.3',
    },
    mariadb: {
      image: 'mariadb:11.2.2',
      metrics: 'prom/mysqld-exporter:v0.15.1',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.16',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.35.1',
    },
    esphome: {
      image: 'esphome/esphome:2023.12.9',
    },
    grafana: {
      image: 'grafana/grafana:10.3.1',
    },
    loki: {
      server: '5.41.8',
      fluentbit: '0.42.0',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.1.5',
    },
    node_red: {
      image: 'nodered/node-red:3.1.3-18',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.4',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v8.0.26',
    },
    prometheus: {
      chart: '25.10.0',
    },
    blackbox_exporter: {
      chart: '8.9.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.8.6',
      },
      server: {
        chart: '0.9.14',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.30.1-alpine',
    },
    nextcloud: {
      image: 'nextcloud:28.0.1-apache',
    },
    redis: {
      image: 'redis:7.2.4-alpine',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.23.1',
    },
    registry: {
      image: 'registry:2',
    },
  },
}
