{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.11.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:25112023',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20231004',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.27.1',
    },
    kubernetes_reflector: {
      chart: '7.1.216',
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
      image: 'restic/restic:0.16.2',
    },
    traefik: {
      chart: '25.0.0',
      repo: 'traefik',
      tag: 'v2.10.6',
    },
    blocky: {
      image: 'spx01/blocky:v0.22',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:02122023',
    },
    authelia: {
      image: 'authelia/authelia:4.37.5',
    },
    cert_manager: {
      chart: 'v1.13.2',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.13.2',
    },
    mariadb: {
      image: 'mariadb:11.2.2',
      metrics: 'prom/mysqld-exporter:v0.15.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.15',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.34.0',
    },
    esphome: {
      image: 'esphome/esphome:2023.11',
    },
    grafana: {
      image: 'grafana/grafana:10.2.2',
    },
    loki: {
      server: '5.39.0',
      fluentbit: '0.40.0',
    },
    frigate: {
      image: 'ghcr.io/blakeblackshear/frigate:0.12.1',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2023.11.3',
    },
    node_red: {
      image: 'nodered/node-red:3.1.1-14',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.3',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v7.5.176',
    },
    prometheus: {
      chart: '25.8.0',
    },
    blackbox_exporter: {
      chart: '8.6.1',
    },
    victoria_metrics: {
      alert: {
        chart: '0.8.3',
      },
      server: {
        chart: '0.9.12',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.30.1-alpine',
    },
    nextcloud: {
      image: 'nextcloud:27.1.4-apache',
    },
    redis: {
      image: 'redis:7.2.3-alpine',
    },
    freshrss: {
      image: 'freshrss/freshrss:1.22.1',
    },
  },
}
