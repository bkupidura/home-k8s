{
  local s = $.k.storage.v1,
  storage+: {
    class_truenas_nfs: s.storageClass.new('truenas-nfs')
                       + s.storageClass.withProvisioner('org.democratic-csi.nfs')
                       + s.storageClass.withAllowVolumeExpansion(true)
                       + s.storageClass.withReclaimPolicy('Delete')
                       + s.storageClass.withVolumeBindingMode('Immediate')
                       + s.storageClass.withMountOptions(['noatime', 'nfsvers=4'])
                       + s.storageClass.withParameters({
                         fsType: 'nfs',
                       }),
    class_truenas_iscsi: s.storageClass.new('truenas-iscsi')
                         + s.storageClass.withProvisioner('org.democratic-csi.iscsi')
                         + s.storageClass.withAllowVolumeExpansion(true)
                         + s.storageClass.withReclaimPolicy('Delete')
                         + s.storageClass.withVolumeBindingMode('Immediate')
                         + s.storageClass.withMountOptions([])
                         + s.storageClass.withParameters({
                           fsType: 'ext4',
                           'csi.storage.k8s.io/node-stage-secret-name': 'democratic-csi-iscsi-chap',
                           'csi.storage.k8s.io/node-stage-secret-namespace': 'democratic-csi',
                         }),
  },
  democratic_csi: {
    namespace: $.k.core.v1.namespace.new('democratic-csi'),
    iscsi_chap: $.k.core.v1.secret.new('democratic-csi-iscsi-chap', {})
                + $.k.core.v1.secret.withStringData({
                  'node-db.node.session.auth.authmethod': 'CHAP',
                  'node-db.node.session.auth.username': std.extVar('secrets').democratic_csi.iscsi.auth.username,
                  'node-db.node.session.auth.password': std.extVar('secrets').democratic_csi.iscsi.auth.password,
                })
                + $.k.core.v1.secret.metadata.withNamespace('democratic-csi'),
    helm_nfs: $._custom.helm.new('democratic-csi-nfs', 'democratic-csi', 'https://democratic-csi.github.io/charts', $._version.democratic_csi.chart, 'democratic-csi', {
      controller: {
        driver: {
          image: $._version.democratic_csi.image,
          imagePullPolicy: 'IfNotPresent',
          resources: {
            requests: {
              memory: '60Mi',
            },
            limits: {
              memory: '120Mi',
            },
          },
        },
        externalAttacher: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
        externalProvisioner: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
        externalResizer: {
          resources: {
            requests: {
              memory: '15Mi',
            },
            limits: {
              memory: '30Mi',
            },
          },
        },
        externalSnapshotter: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
      },
      csiProxy: {
        resources: {
          requests: {
            memory: '5Mi',
          },
          limits: {
            memory: '10Mi',
          },
        },
      },
      node: {
        driver: {
          image: $._version.democratic_csi.image,
          imagePullPolicy: 'IfNotPresent',
          resources: {
            requests: {
              memory: '60Mi',
            },
            limits: {
              memory: '120Mi',
            },
          },
        },
        cleanup: {
          resources: {
            requests: {
              memory: '5Mi',
            },
            limits: {
              memory: '10Mi',
            },
          },
        },
        driverRegistrar: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
      },
      csiDriver: {
        name: 'org.democratic-csi.nfs',
        fsGroupPolicy: 'File',
      },
      storageClasses: [],
      volumeSnapshotClasses: [],
      driver: {
        config: {
          driver: 'freenas-api-nfs',
          httpConnection: {
            protocol: 'https',
            host: std.extVar('secrets').democratic_csi.http.host,
            port: 443,
            username: std.extVar('secrets').democratic_csi.http.username,
            password: std.extVar('secrets').democratic_csi.http.password,
            allowInsecure: true,
            apiVersion: 2,
          },
          zfs: {
            datasetParentName: std.extVar('secrets').democratic_csi.nfs.dataset,
            detachedSnapshotsDatasetParentName: std.extVar('secrets').democratic_csi.nfs.dataset_snapshot,
            datasetEnableQuotas: true,
            datasetEnableReservation: false,
            datasetPermissionsMode: '0777',
            datasetPermissionsUser: std.extVar('secrets').democratic_csi.nfs.user.id,
            datasetPermissionsGroup: std.extVar('secrets').democratic_csi.nfs.group.id,
          },
          nfs: {
            shareHost: std.extVar('secrets').democratic_csi.nfs.host,
            shareAlldirs: false,
            shareAllowedHosts: std.extVar('secrets').democratic_csi.nfs.host_allowed,
            shareAllowedNetworks: [],
            shareMaprootUser: '',
            shareMaprootGroup: '',
            shareMapallUser: std.extVar('secrets').democratic_csi.nfs.user.name,
            shareMapallGroup: std.extVar('secrets').democratic_csi.nfs.user.name,
          },
        },
      },
    }),
    helm_iscsi: $._custom.helm.new('democratic-csi-iscsi', 'democratic-csi', 'https://democratic-csi.github.io/charts', $._version.democratic_csi.chart, 'democratic-csi', {
      controller: {
        driver: {
          image: $._version.democratic_csi.image,
          imagePullPolicy: 'IfNotPresent',
          resources: {
            requests: {
              memory: '60Mi',
            },
            limits: {
              memory: '120Mi',
            },
          },
        },
        externalAttacher: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
        externalProvisioner: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
        externalResizer: {
          resources: {
            requests: {
              memory: '15Mi',
            },
            limits: {
              memory: '30Mi',
            },
          },
        },
        externalSnapshotter: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
      },
      csiProxy: {
        resources: {
          requests: {
            memory: '5Mi',
          },
          limits: {
            memory: '10Mi',
          },
        },
      },
      node: {
        driver: {
          image: $._version.democratic_csi.image,
          imagePullPolicy: 'IfNotPresent',
          resources: {
            requests: {
              memory: '60Mi',
            },
            limits: {
              memory: '120Mi',
            },
          },
        },
        cleanup: {
          resources: {
            requests: {
              memory: '5Mi',
            },
            limits: {
              memory: '10Mi',
            },
          },
        },
        driverRegistrar: {
          resources: {
            requests: {
              memory: '10Mi',
            },
            limits: {
              memory: '20Mi',
            },
          },
        },
      },
      csiDriver: {
        name: 'org.democratic-csi.iscsi',
      },
      storageClasses: [],
      volumeSnapshotClasses: [],
      driver: {
        config: {
          driver: 'freenas-api-iscsi',
          httpConnection: {
            protocol: 'https',
            host: std.extVar('secrets').democratic_csi.http.host,
            port: 443,
            username: std.extVar('secrets').democratic_csi.http.username,
            password: std.extVar('secrets').democratic_csi.http.password,
            allowInsecure: true,
            apiVersion: 2,
          },
          zfs: {
            datasetParentName: std.extVar('secrets').democratic_csi.iscsi.dataset,
            detachedSnapshotsDatasetParentName: std.extVar('secrets').democratic_csi.iscsi.dataset_snapshot,
            datasetEnableQuotas: true,
            zvolCompression: false,
            zvolDedup: false,
            volEnableReservation: false,
            zvolBlocksize: '128K',
          },
          iscsi: {
            targetPortal: std.extVar('secrets').democratic_csi.iscsi.portal,
            targetPortals: [],
            interface: '',
            namePrefix: 'csi-',
            nameSuffix: '',
            targetGroups: [
              {
                targetGroupPortalGroup: std.extVar('secrets').democratic_csi.iscsi.target_group.portal_group,
                targetGroupInitiatorGroup: std.extVar('secrets').democratic_csi.iscsi.target_group.initiator_group,
                targetGroupAuthType: 'CHAP',
                targetGroupAuthGroup: std.extVar('secrets').democratic_csi.iscsi.target_group.auth_group,
              },
            ],
            extentInsecureTpc: true,
            extentXenCompat: false,
            extentDisablePhysicalBlocksize: true,
            extentBlocksize: 512,
            extentRpm: '7200',
            extentAvailThreshold: 0,
          },
        },
      },
    }),
  },
}
