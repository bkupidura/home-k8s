{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.11.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:24022024',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20240212',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.29.0',
    },
    kubernetes_reflector: {
      chart: '7.1.256',
    },
    metallb: {
      chart: '0.14.3',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.14.3',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.14.3',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.8.0',
    },
    longhorn: {
      chart: '1.6.0',
    },
    restic: {
      image: 'restic/restic:0.16.4',
    },
    traefik: {
      chart: '26.1.0',
      repo: 'traefik',
      tag: 'v2.11.0',
    },
    blocky: {
      image: 'spx01/blocky:v0.23',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:26022024',
    },
    authelia: {
      image: 'authelia/authelia:4.37.5',
    },
    cert_manager: {
      chart: 'v1.14.3',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.14.3',
    },
    mariadb: {
      image: 'mariadb:11.3.2',
      metrics: 'prom/mysqld-exporter:v0.15.1',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.16',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.35.3',
    },
    esphome: {
      image: 'esphome/esphome:2024.2.1',
    },
    grafana: {
      image: 'grafana/grafana:10.3.3',
    },
    loki: {
      server: '5.43.3',
      fluentbit: '0.43.0',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2024.2.5',
    },
    node_red: {
      image: 'nodered/node-red:3.1.5-18',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.4',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v8.0.28',
    },
    prometheus: {
      chart: '25.14.0',
    },
    blackbox_exporter: {
      chart: '8.1.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.9.1',
      },
      server: {
        chart: '0.9.15',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.30.3-alpine',
    },
    nextcloud: {
      image: 'nextcloud:28.0.2-apache',
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
