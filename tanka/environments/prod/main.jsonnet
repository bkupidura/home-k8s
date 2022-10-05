(import 'version.jsonnet') +
(import 'custom-resources.libsonnet') +
(import 'namespace.libsonnet') +
(import 'secret.libsonnet') +
(import 'basic-alerts.libsonnet') +
(import 'victoriametrics.libsonnet') +
(import 'coredns.libsonnet') +
(import 'kubefledged.libsonnet') +
(import 'kubernetes-descheduler.libsonnet') +
(import 'kubernetes-reflector.libsonnet') +
(import 'metallb.libsonnet') +
(import 'chrony.libsonnet') +
(import 'traefik.libsonnet') +
(import 'longhorn.libsonnet') +
(import 'debugpod.libsonnet') +
(import 'blocky.libsonnet') +
(import 'cert-manager.libsonnet') +
(import 'nut.libsonnet') +
(import 'authelia.libsonnet') +
(import 'waf.libsonnet') +
(import 'k8s-dashboard.libsonnet') +
(import 'broker-ha.libsonnet') +
(import 'loki.libsonnet') +
(import 'mariadb.libsonnet') +
(import 'grafana.libsonnet') +
(import 'unifi.libsonnet') +
(import 'restic-server.libsonnet') +
(import 'home-assistant.libsonnet') +
(import 'node-red.libsonnet') +
(import 'zigbee2mqtt.libsonnet') +
(import 'frigate.libsonnet') +
(import 'recorder.libsonnet') +
(import 'sms-gammu.libsonnet') +
(import 'esphome.libsonnet') +
{
  _config:: {
    restore: false,
    vip: {
      dns: '10.0.10.40',
      ingress: '10.0.10.42',
      mqtt: '10.0.10.43',
      ntp: '10.0.10.45',
      home_assistant: '10.0.10.46',
      waf: '10.0.10.47',
    },
    tz: 'Europe/Warsaw',
    chrony: {
      allow: [
        '10.0.120.0/24',
        '10.0.150.0/24',
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
      conditional: {
        mapping: { home: '10.0.120.1' },
      },
      custom_dns: {
        mapping: {
          [std.format('esphome.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('k8s.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('grafana.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('storage.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('traefik.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('alertmanager.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('vm-server.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('vm-alert.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('frigate.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('recorder.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('unifi.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('node-red.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('z2m.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('ha.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('auth.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('restic.%s', std.extVar('secrets').domain)]: $._config.vip.ingress,
          [std.format('mqtt.%s', std.extVar('secrets').domain)]: $._config.vip.mqtt,
        },
      },
      blacklist: {
        malware: [
          'http://hole.cert.pl/domains/domains_hosts.txt',
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
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/hostfile.txt',
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/adguard_mobile_host.txt',
          'https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/adservers.txt',
          'https://blocklistproject.github.io/Lists/ads.txt',
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
      ip_whitelist: [
        '10.0.120.0/24',
        '10.0.130.0/24',
      ],
    },
    waf: {
      server: {
        ha: {
          rules: [
            'SecRuleRemoveById 920273',
            'SecRuleRemoveById 921180',
            'SecRuleRemoveById 931130',
            'SecRuleRemoveById 942432',
            'SecRuleRemoveById 920300',
            'SecRuleRemoveById 920272',
            'SecRuleRemoveById 942421',
            'SecRuleRemoveById 942340',
            'SecRuleRemoveById 942210',
            'SecRuleRemoveById 942450',
            'SecRuleRemoveById 942460',
            'SecRuleRemoveById 941120',
            'SecRuleRemoveById 941100',
            'SecRuleRemoveById 932140',
          ],
        },
        auth: {
          rules: [
            'SecRuleRemoveById 942421',
            'SecRuleRemoveById 920273',
            'SecRuleRemoveById 920272',
            'SecRuleRemoveById 931130',
            'SecRuleRemoveById 941101',
          ],
        },
      },
    },
  },
}
