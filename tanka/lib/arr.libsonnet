{
  local v1 = $.k.core.v1,
  local p = v1.persistentVolumeClaim,
  local s = v1.service,
  local st = $.k.storage.v1,
  local c = v1.container,
  local d = $.k.apps.v1.deployment,
  arr: {
    arr: $.k.core.v1.namespace.new('arr'),
    pvc: p.new('media')
         + p.metadata.withNamespace('arr')
         + p.spec.withAccessModes(['ReadWriteMany'])
         + p.spec.withStorageClassName(std.get($.storage.class_truenas_nfs.metadata, 'name'))
         + p.spec.resources.withRequests({ storage: '3000Gi' }),
  },
}
