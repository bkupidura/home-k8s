{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.10.0',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:10122022',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20221130',
    },
    kubefledged: {
      chart: 'v0.10.0',
    },
    kubernetes_descheduler: {
      chart: '0.24.1',
    },
    kubernetes_reflector: {
      chart: '6.1.47',
    },
    metallb: {
      chart: '0.13.7',
      controller: {
        repo: 'quay.io/metallb/controller',
        tag: 'v0.13.7',
      },
      speaker: {
        repo: 'quay.io/metallb/speaker',
        tag: 'v0.13.7',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.8.0',
    },
    longhorn: {
      chart: '1.4.0',
    },
    ceph: {
      chart: 'v1.9.3',
      image: 'quay.io/ceph/ceph:v16.2.9-20220519',
    },
    restic: {
      image: 'restic/restic:0.14.0',
      server: 'restic/rest-server:0.11.0',
    },
    traefik: {
      chart: '17.0.5',
      repo: 'traefik',
      tag: 'v2.9.6',
    },
    blocky: {
      image: 'spx01/blocky:v0.20',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:10122022',
    },
    authelia: {
      image: 'authelia/authelia:4.37.3',
    },
    cert_manager: {
      chart: 'v1.10.1',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.10.1',
    },
    kubernetes_dashboard: {
      chart: '6.0.0',
    },
    mariadb: {
      image: 'mariadb:10.9.4',
      metrics: 'prom/mysqld-exporter:v0.14.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.6b1',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.28.4',
    },
    esphome: {
      image: 'esphome/esphome:2022.11',
    },
    grafana: {
      image: 'grafana/grafana:9.3.1',
    },
    loki: {
      chart: '2.8.9',
    },
    frigate: {
      image: 'blakeblackshear/frigate:0.11.1',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2023.1.4',
    },
    node_red: {
      image: 'nodered/node-red:3.0.2-18',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:0.0.4.6',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.2',
    },
    unifi: {
      image: 'jacobalberty/unifi:v7.3.76',
    },
    prometheus: {
      chart: '19.3.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.5.13',
      },
      server: {
        chart: '0.8.50',
      },
    },
  },
}
