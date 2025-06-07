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
from schemas import pod as schema_pod

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--config-file", required=True, help="config file")
args = parser.parse_args()


with open(args.config_file, "r") as f:
    config = yaml.safe_load(f)

validator_mapping = {
    "Deployment": schema_deployment.Validator(
        config["validators"].get("deployment", dict())
    ),
    "IngressRoute": schema_ingress_route.Validator(
        config["validators"].get("ingress_route", dict())
    ),
    "DaemonSet": schema_daemonset.Validator(
        config["validators"].get("daemonset", dict())
    ),
    "Service": schema_service.Validator(config["validators"].get("service", dict())),
    "CronJob": schema_cron_job.Validator(config["validators"].get("cron_job", dict())),
    "StatefulSet": schema_statefulset.Validator(
        config["validators"].get("statefulset", dict())
    ),
    "Pod": schema_pod.Validator(config["validators"].get("pod", dict())),
}

k8s_definitions = yaml.safe_load_all(sys.stdin)

broken_manifests = list()

for manifests in k8s_definitions:
    for manifest in manifests["items"]:
        for validator_kind, validator in validator_mapping.items():
            if manifest["kind"] != validator_kind:
                continue
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
