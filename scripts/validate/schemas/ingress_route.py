from schema import Schema, And, Or, Optional, SchemaError


class MiddlewareRequiredSchema(Schema):
    _required_anyof_middlewares = [
        {"name": "auth-authelia", "namespace": "traefik-system"},
        {"name": "lan-whitelist", "namespace": "traefik-system"},
        {"name": "languest-whitelist", "namespace": "traefik-system"},
        {"name": "lanmgmt-whitelist", "namespace": "traefik-system"},
        {"name": "lanhypervisor-whitelist", "namespace": "traefik-system"},
    ]

    def validate(self, data, _is_middlewareRequired_schema=True):
        data = super(MiddlewareRequiredSchema, self).validate(
            data, _is_middlewareRequired_schema=False
        )
        if _is_middlewareRequired_schema:
            anyof_present = False
            for m in self._required_anyof_middlewares:
                if m in data:
                    anyof_present = True
            if not anyof_present:
                raise SchemaError(
                    f"any of required middlewares not present {self._required_anyof_middlewares}"
                )
        return data


validator = [
    {
        "name": "generic",
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "traefik.io/v1alpha1"),
                "kind": And(str, lambda x: x == "IngressRoute"),
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
                                    "middlewares": MiddlewareRequiredSchema([dict]),
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
