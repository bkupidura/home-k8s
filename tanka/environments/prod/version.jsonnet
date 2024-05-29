{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.11.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:25052024',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20240427',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.29.0',
    },
    kubernetes_reflector: {
      chart: '7.1.262',
    },
    metallb: {
      chart: '0.14.5',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.14.5',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.14.5',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.8.0',
    },
    longhorn: {
      chart: '1.6.2',
    },
    restic: {
      image: 'restic/restic:0.16.4',
    },
    traefik: {
      chart: '27.0.2',
      repo: 'traefik',
      tag: 'v2.11.3',
    },
    blocky: {
      image: 'spx01/blocky:v0.24',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:25052024',
    },
    authelia: {
      image: 'authelia/authelia:4.38.8',
    },
    cert_manager: {
      chart: 'v1.14.5',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.14.5',
    },
    mariadb: {
      image: 'mariadb:11.3.2',
      metrics: 'prom/mysqld-exporter:v0.15.1',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.17',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.37.1',
    },
    esphome: {
      image: 'esphome/esphome:2024.5.3',
    },
    grafana: {
      image: 'grafana/grafana:11.0.0',
    },
    loki: {
      server: '6.6.2',
      fluentbit: '0.46.7',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.5.5',
    },
    node_red: {
      image: 'nodered/node-red:3.1.9-18',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.5',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v8.1.113',
    },
    prometheus: {
      chart: '25.21.0',
    },
    blackbox_exporter: {
      chart: '8.17.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.9.8',
      },
      server: {
        chart: '0.9.21',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.30.5-alpine',
    },
    nextcloud: {
      image: 'nextcloud:29.0.0-apache',
    },
    redis: {
      image: 'redis:7.2.5-alpine',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.24.0',
    },
    registry: {
      image: 'registry:2',
    },
  },
}
