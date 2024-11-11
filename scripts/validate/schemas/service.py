from schema import Schema, And, Or, Optional

validator = [
    {
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "v1"),
                "kind": And(str, lambda x: x == "Service"),
            },
            ignore_extra_keys=True,
        ),
        "validators": [
            {
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
        ],
    },
    {
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "v1"),
                "kind": And(str, lambda x: x == "Service"),
                "spec": {
                    "type": And(str, lambda x: x == "LoadBalancer"),
                },
            },
            ignore_extra_keys=True,
        ),
        "validators": [
            {
                "schema": Schema(
                    {
                        "spec": {
                            "externalTrafficPolicy": And(str, lambda x: x == "Local"),
                        },
                    },
                    ignore_extra_keys=True,
                ),
            },
        ],
    },
]
