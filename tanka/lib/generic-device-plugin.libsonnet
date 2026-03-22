{
  local v1 = $.k.core.v1,
  local s = v1.service,
  local c = v1.container,
  local d = $.k.apps.v1.daemonSet,
  generic_device_plugin: {
    daemonset: d.new('generic-device-plugin',
                     [
                       c.new('generic-device-plugin', $._version.generic_device_plugin.image)
                       + c.withImagePullPolicy('IfNotPresent')
                       + c.withPorts(v1.containerPort.newNamed(8080, 'http'))
                       + c.resources.withRequests({ memory: '10Mi', cpu: '50m' })
                       + c.resources.withLimits({ memory: '20Mi', cpu: '50m' })
                       + c.securityContext.withPrivileged(true)
                       + c.withVolumeMounts([
                         v1.volumeMount.new('var-lib-kubelet-device-plugins', '/var/lib/kubelet/device-plugins', false),
                         v1.volumeMount.new('dev', '/dev', false),
                       ])
                       + c.withArgs([
                         '--device',
                         std.manifestYamlDoc({
                           name: 'mobile',
                           groups: [
                             { paths: [{ path: '/dev/ttyUSB0', mountPath: '/dev/mobile' }] },
                           ],
                         }),
                         '--device',
                         std.manifestYamlDoc({
                           name: 'video-dri',
                           groups: [
                             { paths: [{ path: '/dev/dri/renderD128', mountPath: '/dev/dri/renderD128' }] },
                           ],
                         }),
                         '--device',
                         std.manifestYamlDoc({
                           name: 'ups',
                           groups: [
                             { paths: [{ path: '/dev/bus/usb/001/004', mountPath: '/dev/bus/usb/001/004' }] },
                           ],
                         }),
                         '--device',
                         std.manifestYamlDoc({
                           name: 'zigbee',
                           groups: [
                             { paths: [{ path: '/dev/ttyACM0', mountPath: '/dev/ttyACM0' }] },
                           ],
                         }),
                       ])
                       + c.securityContext.withReadOnlyRootFilesystem(true)
                       + c.livenessProbe.httpGet.withPath('/health')
                       + c.livenessProbe.httpGet.withPort('http')
                       + c.livenessProbe.withInitialDelaySeconds(30)
                       + c.livenessProbe.withPeriodSeconds(10)
                       + c.livenessProbe.withTimeoutSeconds(2),
                     ],
                     { 'app.kubernetes.io/name': 'generic-device-plugin' })
               + d.spec.template.spec.withVolumes([
                 v1.volume.fromHostPath('var-lib-kubelet-device-plugins', '/var/lib/kubelet/device-plugins') + v1.volume.hostPath.withType('Directory'),
                 v1.volume.fromHostPath('dev', '/dev') + v1.volume.hostPath.withType('Directory'),
               ])
               + d.metadata.withNamespace('kube-system')
               + d.spec.updateStrategy.withType('RollingUpdate')
               + d.spec.template.spec.withTerminationGracePeriodSeconds(5)
               + d.spec.template.metadata.withAnnotations({
                 'prometheus.io/scrape': 'true',
                 'prometheus.io/port': '8080',
               }),
  },
}
