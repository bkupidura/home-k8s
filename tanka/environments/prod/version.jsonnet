{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.10.0',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:15102022',
    },
    ubuntu: {
      image: 'ubuntu:jammy-20221003',
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
      chart: '1.3.2',
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
      tag: 'v2.9.1',
    },
    blocky: {
      image: 'spx01/blocky:v0.19',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:15102022',
    },
    authelia: {
      image: 'authelia/authelia:4.36.9',
    },
    cert_manager: {
      chart: 'v1.10.0',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.10.0',
    },
    kubernetes_dashboard: {
      chart: '5.11.0',
    },
    mariadb: {
      image: 'mariadb:10.7.6',
      metrics: 'prom/mysqld-exporter:v0.14.0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.1.5',
    },
    zigbee2mqtt: {
      deconz: 'ghcr.io/deconz-community/deconz-docker:2.18.00',
      firmware: 'deCONZ_ConBeeII_0x26780700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.28.0',
    },
    esphome: {
      image: 'esphome/esphome:2022.10',
    },
    grafana: {
      image: 'grafana/grafana:9.2.1',
    },
    loki: {
      chart: '2.8.3',
    },
    frigate: {
      image: 'blakeblackshear/frigate:0.11.1',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2022.10.5',
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
      image: 'jacobalberty/unifi:v7.2.94',
    },
    prometheus: {
      chart: '15.12.0',
    },
    victoria_metrics: {
      alert: {
        chart: '0.5.2',
      },
      server: {
        chart: '0.8.40',
      },
    },
  },
}
