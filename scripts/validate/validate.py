#!/usr/bin/env python3
import sys
import yaml
import json
from schema import Schema, And, SchemaError, Or, Optional

from schemas import deployment as schema_deployment
from schemas import ingress_route as schema_ingress_route
from schemas import daemonset as schema_daemonset
from schemas import service as schema_service
from schemas import cron_job as schema_cron_job

validator_mapping = {
    "deployment": schema_deployment.validator,
    "ingress_route": schema_ingress_route.validator,
    "daemonset": schema_daemonset.validator,
    "service": schema_service.validator,
    "cron_job": schema_cron_job.validator,
}

with open("scripts/validate/config.yaml", "r") as f:
    config = yaml.safe_load(f)

k8s_definitions = yaml.safe_load_all(sys.stdin)


def run_checks(manifest, validator, validator_config, validator_full_name):
    all_errors = list()
    for check in validator["validators"]:
        manifest_full_name = f"{manifest['metadata'].get('namespace')}/{manifest['metadata'].get('name')}"

        if validator_config is not None and manifest_full_name in validator_config.get(
            check["name"], dict()
        ).get("skip", list()):
            continue

        try:
            check["schema"].validate(manifest)
        except SchemaError as e:
            all_errors.append(
                {"check": f"{validator_full_name}/{check['name']}", "errors": e.autos}
            )
    return all_errors


broken_manifests = list()

for manifests in k8s_definitions:
    for manifest in manifests["items"]:
        for validator_kind, validators in validator_mapping.items():
            for validator in validators:
                validator_full_name = f"{validator_kind}/{validator['name']}"

                if validator_full_name not in config["validators"].keys():
                    continue

                try:
                    validator["filter"].validate(manifest)
                except SchemaError as e:
                    continue

                errors = run_checks(
                    manifest,
                    validator,
                    config["validators"][validator_full_name],
                    validator_full_name,
                )
                if len(errors) > 0:
                    broken_manifests.append(
                        {
                            "kind": manifest["kind"],
                            "name": manifest.get("metadata", dict()).get("name"),
                            "namespace": manifest.get("metadata", dict()).get(
                                "namespace"
                            ),
                            "errors": errors,
                        }
                    )

print(json.dumps(broken_manifests, indent=4))
