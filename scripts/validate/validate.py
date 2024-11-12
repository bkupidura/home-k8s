#!/usr/bin/env python3
import sys
import yaml
import json
import argparse

from schemas import deployment as schema_deployment
from schemas import ingress_route as schema_ingress_route
from schemas import daemonset as schema_daemonset
from schemas import service as schema_service
from schemas import cron_job as schema_cron_job
from schemas import statefulset as schema_statefulset

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--config-file", required=True, help="config file")
args = parser.parse_args()


with open(args.config_file, "r") as f:
    config = yaml.safe_load(f)

validator_mapping = {
    "deployment": schema_deployment.Validator(
        config["validators"].get("deployment", dict())
    ),
    "ingress_route": schema_ingress_route.Validator(
        config["validators"].get("ingress_route", dict())
    ),
    "daemonset": schema_daemonset.Validator(
        config["validators"].get("daemonset", dict())
    ),
    "service": schema_service.Validator(config["validators"].get("service", dict())),
    "cron_job": schema_cron_job.Validator(config["validators"].get("cron_job", dict())),
    "statefulset": schema_statefulset.Validator(
        config["validators"].get("statefulset", dict())
    ),
}

k8s_definitions = yaml.safe_load_all(sys.stdin)

broken_manifests = list()

for manifests in k8s_definitions:
    for manifest in manifests["items"]:
        for validator_kind, validator in validator_mapping.items():
            errors = validator.run_checks(manifest)
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
