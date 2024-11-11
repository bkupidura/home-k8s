#!/usr/bin/env python3
import sys
import yaml
import json
from schema import Schema, And, SchemaError, Or, Optional

from schemas import deployment as schema_deployment
from schemas import ingress_route as schema_ingress_route
from schemas import daemonset as schema_daemonset
from schemas import service as schema_service

validators = {
    "deployment": schema_deployment.validator,
    "ingress_route": schema_ingress_route.validator,
    "daemonset": schema_daemonset.validator,
    "service": schema_service.validator,
}


def run_checks(manifest, validator):
    all_errors = list()
    for check in validator["validators"]:
        manifest_path = f"{manifest['metadata'].get('namespace')}/{manifest['metadata'].get('name')}"
        if manifest_path in check.get("exceptions", list()):
            continue
        try:
            check["schema"].validate(manifest)
        except SchemaError as e:
            all_errors.append(e.autos)
    return all_errors


manifests = yaml.safe_load_all(sys.stdin)
broken_manifests = list()

for manifest in manifests:
    for validator_kind in validators.values():
        for validator in validator_kind:
            try:
                validator["filter"].validate(manifest)
            except SchemaError:
                continue
            errors = run_checks(manifest, validator)
            if len(errors) > 0:
                broken_manifests.append(
                    {
                        "kind": manifest["kind"],
                        "name": manifest.get("metadata", dict()).get("name"),
                        "namespace": manifest.get("metadata", dict()).get("namespace"),
                        "errors": errors,
                    }
                )

print(json.dumps(broken_manifests, indent=4))
