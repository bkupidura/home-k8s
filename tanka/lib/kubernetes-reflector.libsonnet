{
  kubernetes_reflector: {
    helm: $._custom.helm.new('reflector', 'reflector', 'https://emberstack.github.io/helm-charts', $._version.kubernetes_reflector.chart, 'kube-system', {
      resources: {
        requests: { memory: '128Mi' },
        limits: { memory: '256Mi' },
      },
    }),
  },
}
