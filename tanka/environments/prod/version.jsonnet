{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.10.1',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:15042023',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20230308',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.26.1',
    },
    kubernetes_reflector: {
      chart: '7.0.151',
    },
    metallb: {
      chart: '0.13.9',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.13.9',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.13.9',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.8.0',
    },
    longhorn: {
      chart: '1.4.1',
    },
    ceph: {
      chart: 'v1.9.3',
      image: 'quay.io/ceph/ceph:v16.2.9-20220519',
    },
    restic: {
      image: 'restic/restic:0.15.1',
      server: 'restic/rest-server:0.11.0',
    },
    traefik: {
      chart: '22.1.0',
      repo: 'traefik',
      tag: 'v2.9.10',
    },
    blocky: {
      image: 'spx01/blocky:v0.21',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:15042023',
    },
    authelia: {
      image: 'authelia/authelia:4.37.5',
    },
    cert_manager: {
      chart: 'v1.11.1',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.11.1',
    },
    kubernetes_dashboard: {
      chart: '6.0.0',
    },
    mariadb: {
      image: 'mariadb:10.11.2',
      metrics: 'prom/mysqld-exporter:v0.14.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.12',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.30.3',
    },
    esphome: {
      image: 'esphome/esphome:2023.3.2',
    },
    grafana: {
      image: 'grafana/grafana:9.4.7',
    },
    loki: {
      chart: '2.9.10',
    },
    frigate: {
      image: 'ghcr.io/blakeblackshear/frigate:0.12.0',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2023.4.5',
    },
    node_red: {
      image: 'nodered/node-red:3.0.2-18',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:2.0',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.2',
    },
    unifi: {
      image: 'jacobalberty/unifi:v7.3.83',
    },
    prometheus: {
      chart: '20.2.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.5.22',
      },
      server: {
        chart: '0.8.58',
      },
    },
  },
}
