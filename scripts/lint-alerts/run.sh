#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."

RULES_FILE=$(mktemp -t pint-rules).yaml
PF_PID=""
cleanup() {
  rm -f "$RULES_FILE"
  [ -n "$PF_PID" ] && kill "$PF_PID" 2>/dev/null || true
}
trap cleanup EXIT

./scripts/tanka eval tanka/environments/prod -e 'victoria_metrics.rules_rendered' \
  | python3 -c 'import json, sys, yaml; print(yaml.dump({"groups": json.load(sys.stdin)}))' \
  > "$RULES_FILE"

kubectl -n monitoring port-forward svc/victoria-metrics-single-server 8428:8428 >/dev/null 2>&1 &
PF_PID=$!
sleep 2

pint --config scripts/lint-alerts/pint.hcl lint --min-severity bug --show-duplicates "$RULES_FILE"
