from . import ValidatorBase
from schema import Schema, And, SchemaError


class MiddlewareRequiredSchema(Schema):
    def __init__(self, *args, **kwargs):
        try:
            self.required_middlewares = kwargs.pop("required_middlewares")
        except KeyError:
            pass
        super(MiddlewareRequiredSchema, self).__init__(*args, **kwargs)

    def validate(self, data, _is_middlewareRequired_schema=True):
        data = super(MiddlewareRequiredSchema, self).validate(
            data, _is_middlewareRequired_schema=False
        )
        if _is_middlewareRequired_schema:
            anyof_present = False
            for m in self.required_middlewares:
                if m in data:
                    anyof_present = True
            if not anyof_present:
                raise SchemaError(
                    f"any of required middlewares not present {self.required_middlewares}"
                )
        return data


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
                                            "middlewares": MiddlewareRequiredSchema(
                                                [dict],
                                                required_middlewares=self.conf.get(
                                                    "generic", dict()
                                                )
                                                .get("required_middlewares", dict())
                                                .get("middleware", list()),
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
