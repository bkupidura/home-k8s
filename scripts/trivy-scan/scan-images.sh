#!/usr/bin/env bash
#
# scan-images.sh — scan every image running in the cluster with Trivy and open a
# single consolidated HTML report (clean images omitted).
#
# Env: KUBECONFIG, SEVERITY (default CRITICAL), OPEN (default true).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEVERITY="${SEVERITY:-CRITICAL}"
OPEN="${OPEN:-true}"
OUTDIR="$(mktemp -d)"
report="$OUTDIR/report.html"

for bin in kubectl trivy jq open; do
  command -v "$bin" >/dev/null || { echo "ERROR: '$bin' not found in PATH" >&2; exit 1; }
done

echo "refreshing Trivy DB"
trivy image --download-db-only -q

echo "scanning cluster images (severity: $SEVERITY)"
kubectl get pods -A -o jsonpath='{range .items[*]}{range .spec.initContainers[*]}{.image}{"\n"}{end}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' \
  | sort -u | while read -r img; do
      [ -n "$img" ] || continue
      echo -n '.'
      out="$OUTDIR/$(echo -n $img | tr '/:@' '___').json"
      trivy image -q --scanners vuln --severity "$SEVERITY" --ignore-unfixed \
        --skip-db-update --format json -o "$out" "$img" 2>/dev/null || rm -f "$out"
    done
echo

# merge per-image reports into one, keep only results with findings, label by image
jq -s '{ SchemaVersion:2, ArtifactName:"cluster image scan", ArtifactType:"filesystem",
         Results: [ .[] as $r | $r.Results[]? | select((.Vulnerabilities//[])|length>0)
                    | .Target = ($r.ArtifactName + "  —  " + .Target) ] }' \
   "$OUTDIR"/*.json > "$OUTDIR/merged.json"
trivy convert -q --format template --template "@$SCRIPT_DIR/trivy-report.tpl" -o "$report" "$OUTDIR/merged.json"

echo "report $report"
[ "${OPEN}" = true ] && open "$report"
