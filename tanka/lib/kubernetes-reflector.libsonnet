{
  kubernetes_reflector: {
    network_policy: $._custom.cilium_network_policy.new(
      'reflector',
      'kube-system',
      { matchLabels: { 'app.kubernetes.io/name': 'reflector' } },
      ingress=[],
      egress=[
        {
          toEntities: ['kube-apiserver'],
          toPorts: [
            { ports: [{ port: '6443', protocol: 'TCP' }] },
          ],
        },
      ],
    ),
    helm: $._custom.helm.new('reflector', 'reflector', 'https://emberstack.github.io/helm-charts', $._version.kubernetes_reflector.chart, 'kube-system', {
      resources: {
        requests: { memory: '128Mi' },
        limits: { memory: '256Mi' },
      },
    }),
  },
}
