from . import ValidatorBase
from schema import Schema, And, Optional, SchemaError


def var_restic_host_set(data):
    variables = list()
    for container in data["spec"]["jobTemplate"]["spec"]["template"]["spec"][
        "containers"
    ]:
        for env in container["env"]:
            if env["name"] == "RESTIC_HOST":
                variables.append(env["value"])

    if len(variables) != 1:
        raise SchemaError("zero or multiple RESTIC_HOST variable definition")

    if variables[0] != data["metadata"]["name"].removesuffix("-restore"):
        raise SchemaError(f"wrong RESTIC_HOST value {variables[0]}")

    return True


class Validator(ValidatorBase):
    def __init__(self, *args, **kwargs):
        super(Validator, self).__init__(*args, **kwargs)
        self.name = "cron_job"
        self.validators = [
            {
                "name": "generic",
                "filter": Schema(
                    {
                        "apiVersion": And(str, lambda x: x == "batch/v1"),
                        "kind": And(str, lambda x: x == "CronJob"),
                    },
                    ignore_extra_keys=True,
                ),
                "check": [
                    {
                        "name": "generic",
                        "schema": Schema(
                            {
                                "metadata": {
                                    "name": str,
                                    "namespace": str,
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                    {
                        "name": "restartpolicy_onfailure",
                        "schema": Schema(
                            {
                                "spec": {
                                    "jobTemplate": {
                                        "spec": {
                                            "template": {
                                                "spec": {
                                                    "restartPolicy": And(
                                                        str, lambda x: x == "OnFailure"
                                                    ),
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                ],
            },
            {
                "name": "backup",
                "filter": Schema(
                    {
                        "apiVersion": And(str, lambda x: x == "batch/v1"),
                        "kind": And(str, lambda x: x == "CronJob"),
                        "metadata": {
                            "name": And(str, lambda x: x.endswith("-backup")),
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "check": [
                    {
                        "name": "generic",
                        "schema": Schema(
                            {
                                "spec": {
                                    "concurrencyPolicy": And(
                                        str, lambda x: x == "Forbid"
                                    ),
                                    Optional("suspend"): And(
                                        bool, lambda x: x == False
                                    ),
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                    {
                        "name": "hostname_set",
                        "schema": Schema(
                            And(
                                Schema(
                                    {
                                        "metadata": {
                                            "name": str,
                                        },
                                        "spec": {
                                            "jobTemplate": {
                                                "spec": {
                                                    "template": {
                                                        "spec": {"hostname": str}
                                                    }
                                                }
                                            }
                                        },
                                    },
                                    ignore_extra_keys=True,
                                ),
                                lambda x: x["metadata"]["name"]
                                == f"{x['spec']['jobTemplate']['spec']['template']['spec']['hostname']}-backup",
                            ),
                            ignore_extra_keys=True,
                        ),
                    },
                ],
            },
            {
                "name": "restore",
                "filter": Schema(
                    {
                        "apiVersion": And(str, lambda x: x == "batch/v1"),
                        "kind": And(str, lambda x: x == "CronJob"),
                        "metadata": {
                            "name": And(str, lambda x: x.endswith("-restore")),
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "check": [
                    {
                        "name": "generic",
                        "schema": Schema(
                            {
                                "spec": {
                                    "concurrencyPolicy": And(
                                        str, lambda x: x == "Forbid"
                                    ),
                                    "suspend": And(bool, lambda x: x == True),
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                    {
                        "name": "hostname_set",
                        "schema": Schema(
                            And(
                                Schema(
                                    {
                                        "metadata": {
                                            "name": str,
                                        },
                                        "spec": {
                                            "jobTemplate": {
                                                "spec": {
                                                    "template": {
                                                        "spec": {"hostname": str},
                                                    }
                                                }
                                            }
                                        },
                                    },
                                    ignore_extra_keys=True,
                                ),
                                lambda x: x["metadata"]["name"]
                                == f"{x['spec']['jobTemplate']['spec']['template']['spec']['hostname']}-restore",
                            ),
                            ignore_extra_keys=True,
                        ),
                    },
                    {
                        "name": "env_restic_host_set",
                        "schema": Schema(
                            And(
                                Schema(
                                    {
                                        "metadata": {
                                            "name": str,
                                        },
                                        "spec": {
                                            "jobTemplate": {
                                                "spec": {
                                                    "template": {
                                                        "spec": {
                                                            "containers": [
                                                                Schema(
                                                                    {
                                                                        "env": [
                                                                            Schema(
                                                                                {
                                                                                    "name": And(
                                                                                        str,
                                                                                        lambda x: x
                                                                                        == "RESTIC_HOST",
                                                                                    ),
                                                                                    "value": str,
                                                                                }
                                                                            ),
                                                                        ],
                                                                    },
                                                                    ignore_extra_keys=True,
                                                                ),
                                                            ]
                                                        }
                                                    }
                                                }
                                            }
                                        },
                                    },
                                    ignore_extra_keys=True,
                                ),
                                var_restic_host_set,
                            ),
                            ignore_extra_keys=True,
                        ),
                    },
                ],
            },
        ]
