from . import ValidatorBase
from schema import Schema, And, SchemaError


class Validator(ValidatorBase):
    def __init__(self, *args, **kwargs):
        super(Validator, self).__init__(*args, **kwargs)
        self.name = "ingress_route"
        self.validators = [
            {
                "name": "generic",
                "filter": Schema(
                    {
                        "apiVersion": And(str, lambda x: x == "traefik.io/v1alpha1"),
                        "kind": And(str, lambda x: x == "IngressRoute"),
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
                        "name": "tls_present",
                        "schema": Schema(
                            {
                                "spec": {
                                    "tls": dict,
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                    {
                        "name": "required_middlewares",
                        "schema": Schema(
                            {
                                "spec": {
                                    "routes": [
                                        {
                                            "middlewares": And(
                                                [dict], self.validate_middleware
                                            ),
                                        },
                                    ]
                                }
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                ],
            }
        ]

    def validate_middleware(self, data):
        any_of_required_middlewares = (
            self.conf.get("generic", dict())
            .get("required_middlewares", dict())
            .get("middleware", list())
        )
        any_of_required_middleware_present = False
        for middleware in data:
            if middleware in any_of_required_middlewares:
                any_of_required_middleware_present = True

        if not any_of_required_middleware_present:
            raise SchemaError(
                f"any of required middlewares not present {any_of_required_middlewares}"
            )

        return True
