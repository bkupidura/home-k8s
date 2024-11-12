from . import ValidatorBase
from schema import Schema, And


class Validator(ValidatorBase):
    def __init__(self, *args, **kwargs):
        super(Validator, self).__init__(*args, **kwargs)
        self.name = "service"
        self.validators = [
            {
                "name": "generic",
                "filter": Schema(
                    {
                        "apiVersion": And(str, lambda x: x == "v1"),
                        "kind": And(str, lambda x: x == "Service"),
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
                ],
            },
            {
                "name": "loadbalancer",
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
                "check": [
                    {
                        "name": "externaltrafficpolicy_local",
                        "schema": Schema(
                            {
                                "spec": {
                                    "externalTrafficPolicy": And(
                                        str, lambda x: x == "Local"
                                    ),
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                ],
            },
        ]
