{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.9.3',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:06082022',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20220801',
    },
    kubefledged: {
      chart: 'v0.9.0',
    },
    kubernetes_descheduler: {
      chart: '0.24.1',
    },
    kubernetes_reflector: {
      chart: '6.1.47',
    },
    metallb: {
      chart: '0.13.4',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.13.4',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.13.4',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.7.4-2486-gaa0b3d1d',
    },
    longhorn: {
      chart: '1.3.1',
    },
    ceph: {
      chart: 'v1.9.3',
      image: 'quay.io/ceph/ceph:v16.2.9-20220519',
    },
    restic: {
      image: 'restic/restic:0.13.1',
      server: 'restic/rest-server:0.11.0',
    },
    traefik: {
      chart: '10.24.0',
      repo: 'traefik',
      tag: 'v2.8.1',
    },
    blocky: {
      image: 'spx01/blocky:v0.19',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:06082022',
    },
    authelia: {
      image: 'authelia/authelia:4.36.3',
    },
    cert_manager: {
      chart: 'v1.9.1',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.9.1',
    },
    kubernetes_dashboard: {
      chart: '5.7.0',
    },
    mariadb: {
      image: 'mariadb:10.7.4',
      metrics: 'prom/mysqld-exporter:v0.14.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.4',
    },
    zigbee2mqtt: {
      deconz: 'marthoc/deconz:2.12.03',
      firmware: 'deCONZ_ConBeeII_0x26720700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.27.0',
    },
    esphome: {
      image: 'esphome/esphome:2022.6.2',
    },
    grafana: {
      image: 'grafana/grafana:9.0.6',
    },
    loki: {
      chart: '2.6.4',
    },
    frigate: {
      image: 'blakeblackshear/frigate:0.10.1-amd64',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2022.8.3',
    },
    node_red: {
      image: 'nodered/node-red:3.0.2-16',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:0.0.4.6',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.2',
    },
    unifi: {
      image: 'jacobalberty/unifi:v7.1.68',
    },
    prometheus: {
      chart: '15.12.0',
    },
  },
}
