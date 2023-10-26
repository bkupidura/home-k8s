(import 'version.jsonnet') +
(import 'custom-resources.libsonnet') +
(import 'global-resources.libsonnet') +
(import 'namespace.libsonnet') +
(import 'secret.libsonnet') +
(import 'basic-monitoring.libsonnet') +
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
(import 'broker-ha.libsonnet') +
(import 'loki.libsonnet') +
(import 'mariadb.libsonnet') +
(import 'grafana.libsonnet') +
(import 'unifi.libsonnet') +
(import 'home-assistant.libsonnet') +
(import 'node-red.libsonnet') +
(import 'zigbee2mqtt.libsonnet') +
(import 'frigate.libsonnet') +
(import 'recorder.libsonnet') +
(import 'sms-gammu.libsonnet') +
(import 'esphome.libsonnet') +
(import 'vaultwarden.libsonnet') +
(import 'redis.libsonnet') +
(import 'nextcloud.libsonnet') +
{
  _config:: {
    restore: false,
    core_dns: '10.0.120.1',
    vip: {
      dns: '10.0.10.40',
      ingress: '10.0.10.42',
      mqtt: '10.0.10.43',
      ntp: '10.0.10.45',
      waf: '10.0.10.47',
      webrtc: '10.0.10.48',
    },
    kubernetes_internal_cidr: '10.42.0.0/16',
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
        mapping: {
          home: $._config.core_dns,
          [std.extVar('secrets').domain]: $._config.core_dns,
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
      whitelist: {
        lan: [
          '10.0.120.0/24',
          '10.0.20.0/24',
        ],
        languest: [
          '10.0.120.0/24',
          '10.0.20.0/24',
          '10.0.160.0/24',
        ],
        lanmgmt: [
          '10.0.120.0/24',
          '10.0.20.0/24',
          '10.0.100.0/24',
        ],
      },
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
            'SecRuleRemoveById 942390',
          ],
        },
        vaultwarden: {
          rules: [
            'SecRule ip:too_many45_errors_time "@lt %{TIME_EPOCH}" "phase:3, pass, nolog, setvar:!ip.too_many45_errors_counter, setvar:!ip.too_many45_errors_time, id:990000100"',
            'SecRule RESPONSE_STATUS "@rx ^[45]" "phase:3, pass, nolog, setvar:ip.too_many45_errors_counter=+1, setvar:ip.too_many45_errors_time=%{TIME_EPOCH}, setvar:ip.too_many45_errors_time=+900, id:990000101"',
            'SecRule ip:too_many45_errors_counter "@gt 5" "phase:3, log, drop, id:990000103"',
            'SecRuleRemoveById 942432',
            'SecRuleRemoveById 920273',
            'SecRuleRemoveById 942430',
            'SecRuleRemoveById 942260',
            'SecRuleRemoveById 942431',
            'SecRuleRemoveById 942200',
            'SecRuleRemoveById 942340',
            'SecRuleRemoveById 942370',
            'SecRuleRemoveById 942460',
            'SecRuleRemoveById 949110',
            'SecRuleRemoveById 920274',
            'SecRuleRemoveById 920300',
            'SecRuleRemoveById 920320',
            'SecRuleRemoveById 911100',
            'SecRuleRemoveById 920272',
            'SecRuleRemoveById 942421',
          ],
        },
        auth: {
          rules: [
            'SecRuleRemoveById 942421',
            'SecRuleRemoveById 920273',
            'SecRuleRemoveById 920272',
            'SecRuleRemoveById 931130',
            'SecRuleRemoveById 941101',
            'SecRuleRemoveById 920230',
            'SecRuleRemoveById 932200',
            'SecRuleRemoveById 932190',
            'SecRuleRemoveById 942430',
            'SecRuleRemoveById 942431',
            'SecRuleRemoveById 942432',
            'SecRuleRemoveById 949110',
          ],
        },
        files: {
          rules: [
            'SecRuleRemoveById 942421',
            'SecRuleRemoveById 920273',
            'SecRuleRemoveById 921110',
            'SecRuleRemoveById 933190',
            'SecRuleRemoveById 941100',
            'SecRuleRemoveById 941130',
            'SecRuleRemoveById 941330',
            'SecRuleRemoveById 941340',
            'SecRuleRemoveById 942110',
            'SecRuleRemoveById 942210',
            'SecRuleRemoveById 942340',
            'SecRuleRemoveById 942490',
            'SecRuleRemoveById 942431',
            'SecRuleRemoveById 942460',
            'SecRuleRemoveById 942432',
            'SecRuleRemoveById 949110',
            'SecRuleRemoveById 911100',
            'SecRuleRemoveById 920272',
            'SecRuleRemoveById 942430',
            'SecRuleRemoveById 942130',
            'SecRuleRemoveById 920420',
            'SecRuleRemoveById 942440',
            'SecRuleRemoveById 920274',
            'SecRuleRemoveById 921422',
          ],
        },
      },
    },
  },
}
