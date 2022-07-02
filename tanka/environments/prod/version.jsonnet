{
  _version:: {
    coredns: {
      image: 'coredns/coredns:1.9.3',
    },
    chrony: {
      image: 'ghcr.io/bkupidura/chrony:21052022',
    },
    ubuntu: {
      image: 'ubuntu:focal-20220426',
    },
    kubefledged: {
      chart: 'v0.9.0',
    },
    kubernetes_descheduler: {
      chart: '0.23.1',
    },
    kubernetes_reflector: {
      chart: '6.1.47',
    },
    metallb: {
      chart: '0.12.1',
      controller: {
        repo: 'metallb/controller',
        tag: 'v0.12.1',
      },
      speaker: {
        repo: 'metallb/speaker',
        tag: 'v0.12.1',
      },
    },
    nut: {
      image: 'ghcr.io/k8s-at-home/network-ups-tools:v2.7.4-2486-gaa0b3d1d',
    },
    longhorn: {
      chart: '1.2.4',
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
      chart: '10.19.5',
      repo: 'traefik',
      tag: 'v2.6.6',
    },
    blocky: {
      image: 'spx01/blocky:v0.19',
    },
    waf: {
      image: 'ghcr.io/bkupidura/waf-modsecurity:26052022',
    },
    authelia: {
      image: 'authelia/authelia:4.35.5',
    },
    cert_manager: {
      chart: 'v1.8.0',
      repo: 'quay.io/jetstack/cert-manager-controller',
      tag: 'v1.8.0',
    },
    kubernetes_dashboard: {
      chart: '5.4.1',
    },
    mariadb: {
      chart: '11.0.7',
      registry: 'docker.io',
      repo: 'bitnami/mariadb',
      tag: '10.6.8-debian-10-r0',
    },
    broker_ha: {
      image: 'ghcr.io/bkupidura/broker-ha:0.0.9',
    },
    zigbee2mqtt: {
      deconz: 'marthoc/deconz:2.12.03',
      firmware: 'deCONZ_ConBeeII_0x26720700.bin.GCF',
      image: 'koenkk/zigbee2mqtt:1.25.2',
    },
    esphome: {
      image: 'esphome/esphome:2022.6.1',
    },
    grafana: {
      image: 'grafana/grafana:8.5.3',
    },
    loki: {
      chart: '2.6.4',
    },
    frigate: {
      image: 'blakeblackshear/frigate:0.10.1-amd64',
    },
    home_assistant: {
      image: 'homeassistant/home-assistant:2022.5.5',
    },
    node_red: {
      image: 'nodered/node-red:2.2.2-12',
    },
    recorder: {
      image: 'ghcr.io/bkupidura/recorder:0.0.4.6',
    },
    sms_gammu: {
      image: 'pajikos/sms-gammu-gateway:1.2',
    },
    unifi: {
      image: 'jacobalberty/unifi:v7.1.65',
    },
    prometheus: {
      chart: '15.9.0',
    },
  },
}
