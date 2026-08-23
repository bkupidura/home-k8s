prometheus "victoriametrics" {
  uri     = "http://127.0.0.1:8428"
  timeout = "30s"
}

checks {
  disabled = [
    "promql/rate",
    "promql/range_query",
    "promql/offset",
  ]
}

rule {
  match {
    name = "AutheliaAuthFailure|NUTAlarm|WAF5XXErrors|DMHActionError|DMHMissingVaultKey"
  }
  disable = [ "promql/series" ]
}
rule {
  match {
    name = "HighTemperatureMultipleTimes|K8sDeploymentCountDifference|K8sSTSCountDifference|K8sDaemonSetCountDifference|Watchdog"
  }
  disable = [ "promql/syntax" ]
}
