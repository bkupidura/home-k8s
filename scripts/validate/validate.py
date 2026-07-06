#!/usr/bin/env python3
import sys
import yaml
import json
import argparse

from schema import SchemaError

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
        config["validators"].get("deployment", dict()), config["global"]
    ),
    "IngressRoute": schema_ingress_route.Validator(
        config["validators"].get("ingress_route", dict()), config["global"]
    ),
    "DaemonSet": schema_daemonset.Validator(
        config["validators"].get("daemonset", dict()), config["global"]
    ),
    "Service": schema_service.Validator(
        config["validators"].get("service", dict()), config["global"]
    ),
    "CronJob": schema_cron_job.Validator(
        config["validators"].get("cron_job", dict()), config["global"]
    ),
    "StatefulSet": schema_statefulset.Validator(
        config["validators"].get("statefulset", dict()), config["global"]
    ),
    "Pod": schema_pod.Validator(
        config["validators"].get("pod", dict()), config["global"]
    ),
}

k8s_definitions = yaml.safe_load_all(sys.stdin)

broken_manifests = list()
seen_manifests = dict()

for manifests in k8s_definitions:
    for manifest in manifests["items"]:
        kind = manifest["kind"]
        ns = manifest.get("metadata", dict()).get("namespace")
        name = manifest.get("metadata", dict()).get("name")
        seen_manifests[(kind, ns, name)] = manifest

        for validator_kind, validator in validator_mapping.items():
            if kind != validator_kind:
                continue
            errors = validator.run_checks(manifest)
            if len(errors) > 0:
                broken_manifests.append(
                    {
                        "kind": kind,
                        "name": name,
                        "namespace": ns,
                        "errors": errors,
                    }
                )

obsolete_exceptions = list()
disabled_validators = list()

for validator_kind, validator in validator_mapping.items():
    for v in validator.validators:
        if v["name"] not in validator.conf:
            disabled_validators.append(
                {
                    "validator": v["name"],
                    "resource": validator_kind,
                    "reason": "not enabled",
                }
            )
        validator_config = validator.conf.get(v["name"]) or dict()
        for check in v["check"]:
            check_config = validator_config.get(check["name"]) or dict()
            for skipped_resource in check_config.get("skip", list()):
                ns, _, name = skipped_resource.partition("/")
                manifest = seen_manifests.get((validator_kind, ns, name))
                check_label = f"{validator.name}/{v['name']}/{check['name']}"

                if manifest is None:
                    obsolete_exceptions.append(
                        {
                            "check": check_label,
                            "resource": skipped_resource,
                            "reason": "resource not found in cluster",
                        }
                    )
                    continue

                try:
                    check["schema"].validate(manifest)
                    obsolete_exceptions.append(
                        {
                            "check": check_label,
                            "resource": skipped_resource,
                            "reason": "resource is compliant, exception is not needed",
                        }
                    )
                except SchemaError:
                    pass

output = {
    "violations": broken_manifests,
    "obsolete_exceptions": obsolete_exceptions,
    "disabled_validators": disabled_validators,
}

print(json.dumps(output, indent=4))
