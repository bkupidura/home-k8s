(import 'version.jsonnet') +
(import 'custom-resources.libsonnet') +
(import 'global-resources.libsonnet') +
(import 'namespace.libsonnet') +
(import 'secret.libsonnet') +
(import 'storage.libsonnet') +
(import 'basic-monitoring.libsonnet') +
(import 'authelia.libsonnet') +
(import 'victoriametrics.libsonnet') +
(import 'truenas.libsonnet') +
(import 'loki.libsonnet') +
(import 'coredns.libsonnet') +
(import 'reloader.libsonnet') +
(import 'kubernetes-descheduler.libsonnet') +
(import 'kubernetes-reflector.libsonnet') +
(import 'metallb.libsonnet') +
(import 'chrony.libsonnet') +
(import 'traefik.libsonnet') +
(import 'longhorn.libsonnet') +
(import 'democratic-csi.libsonnet') +
(import 'mariadb.libsonnet') +
(import 'debugpod.libsonnet') +
(import 'blocky.libsonnet') +
(import 'cert-manager.libsonnet') +
(import 'nut.libsonnet') +
(import 'waf.libsonnet') +
(import 'broker-ha.libsonnet') +
(import 'grafana.libsonnet') +
(import 'unifi.libsonnet') +
(import 'home-assistant.libsonnet') +
(import 'node-red.libsonnet') +
(import 'zigbee2mqtt.libsonnet') +
(import 'recorder.libsonnet') +
(import 'sms-gammu.libsonnet') +
(import 'esphome.libsonnet') +
(import 'vaultwarden.libsonnet') +
(import 'valkey.libsonnet') +
(import 'nextcloud.libsonnet') +
(import 'freshrss.libsonnet') +
(import 'registry.libsonnet') +
(import 'paperless.libsonnet') +
(import 'arr.libsonnet') +
(import 'radarr.libsonnet') +
(import 'sonarr.libsonnet') +
(import 'bazarr.libsonnet') +
(import 'nzbget.libsonnet') +
(import 'jellyfin.libsonnet') +
(import 'prowlarr.libsonnet') +
(import 'homer.libsonnet') +
(import 'immich.libsonnet') +
{
  _config:: {
    restore: false,
    update: false,
    vip: {
      dns: '10.0.10.40',
      ingress: '10.0.10.42',
      mqtt: '10.0.10.43',
      ntp: '10.0.10.45',
      valkey: '10.0.10.49',
      waf: '10.0.10.47',
    },
    network: {
      kubernetes: '10.42.0.0/16',
      mgmt: '10.0.100.0/24',
      lan: '10.0.120.0/24',
      iot: '10.0.150.0/24',
      guest: '10.0.160.0/24',
      vpn: '10.0.20.0/24',
    },
    tz: 'Europe/Warsaw',
    chrony: {
      allow: [
        $._config.network.lan,
        $._config.network.iot,
        $._config.network.mgmt,
      ],
      pool: '0.pl.pool.ntp.org',
    },
    metallb: {
      pool: [
        '10.0.10.0/24',
      ],
      peers: [
        {
          my_asn: 64500,
          address: '10.0.120.1',
          asn: 64501,
        },
      ],
    },
    blocky: {
      blacklist: {
        malware: [
          'https://hole.cert.pl/domains/domains_hosts.txt',
          'https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt',
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/KADhosts.txt',
          'https://blocklistproject.github.io/Lists/abuse.txt',
          'https://blocklistproject.github.io/Lists/malware.txt',
          'https://blocklistproject.github.io/Lists/phishing.txt',
          'https://blocklistproject.github.io/Lists/ransomware.txt',
        ],
        ads: [
          'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext',
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/Ad_filter_list_by_Disconnect.txt',
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/adguard_mobile_host.txt',
          'https://blocklistproject.github.io/Lists/fraud.txt',
          'https://blocklistproject.github.io/Lists/scam.txt',
        ],
        privacy: [
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/NoTrack_Tracker_Blocklist.txt',
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/easy_privacy_host.txt',
          'https://blocklistproject.github.io/Lists/tracking.txt',
        ],
      },
    },
    traefik: {
      whitelist: {
        lan: [$._config.network.lan, $._config.network.vpn],
        languest: [$._config.network.lan, $._config.network.vpn, $._config.network.guest],
        lanmgmt: [$._config.network.lan, $._config.network.vpn, $._config.network.mgmt],
        lanhypervisor: [$._config.network.lan, $._config.network.vpn, $._config.network.kubernetes],
      },
    },
  },
}
