from schema import Schema, And, Or, Optional


validator = [
    {
        "name": "generic",
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "batch/v1"),
                "kind": And(str, lambda x: x == "CronJob"),
            },
            ignore_extra_keys=True,
        ),
        "validators": [
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
        "validators": [
            {
                "name": "generic",
                "schema": Schema(
                    {
                        "spec": {
                            "concurrencyPolicy": And(str, lambda x: x == "Forbid"),
                            Optional("suspend"): And(bool, lambda x: x == False),
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
                                            "template": {"spec": {"hostname": str}}
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
        "validators": [
            {
                "name": "generic",
                "schema": Schema(
                    {
                        "spec": {
                            "concurrencyPolicy": And(str, lambda x: x == "Forbid"),
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
                                            "template": {"spec": {"hostname": str}}
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
        ],
    },
]
