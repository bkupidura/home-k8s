{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.10.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:08072023',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20230624',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.27.1',
    },
    kubernetes_reflector: {
      chart: '7.0.190',
    },
    metallb: {
      chart: '0.13.10',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.13.10',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.13.10',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.8.0',
    },
    longhorn: {
      chart: '1.5.0',
    },
    ceph: {
      chart: 'v1.9.3',
      image: 'quay.io/ceph/ceph:v16.2.9-20220519',
    },
    restic: {
      image: 'restic/restic:0.15.2',
      server: 'restic/rest-server:0.12.1',
    },
    traefik: {
      chart: '23.1.0',
      repo: 'traefik',
      tag: 'v2.10.3',
    },
    blocky: {
      image: 'spx01/blocky:v0.21',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:08072023',
    },
    authelia: {
      image: 'authelia/authelia:4.37.5',
    },
    cert_manager: {
      chart: 'v1.12.2',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.12.2',
    },
    kubernetes_dashboard: {
      chart: '6.0.0',
    },
    mariadb: {
      image: 'mariadb:10.11.4',
      metrics: 'prom/mysqld-exporter:v0.15.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.13',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.32.1',
    },
    esphome: {
      image: 'esphome/esphome:2023.6',
    },
    grafana: {
      image: 'grafana/grafana:10.0.1',
    },
    loki: {
      chart: '2.9.10',
    },
    frigate: {
      image: 'ghcr.io/blakeblackshear/frigate:0.12.1',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2023.7.1',
    },
    node_red: {
      image: 'nodered/node-red:3.0.2-18',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0.1',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.3.0',
    },
    unifi: {
      image: 'jacobalberty/unifi:v7.4.156',
    },
    prometheus: {
      chart: '23.0.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.6.4',
      },
      server: {
        chart: '0.8.64',
      },
    },
    vaultwarden: {
      image: 'vaultwarden/server:1.29.0-alpine',
    },
  },
}
