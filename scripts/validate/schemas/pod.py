from . import ValidatorBase
from schema import Schema, And


class Validator(ValidatorBase):
    def __init__(self, *args, **kwargs):
        super(Validator, self).__init__(*args, **kwargs)
        self.name = "pod"
        self.validators = [
            {
                "name": "generic",
                "filter": Schema(
                    {
                        "apiVersion": And(str, lambda x: x == "v1"),
                        "kind": And(str, lambda x: x == "Pod"),
                    },
                    ignore_extra_keys=True,
                ),
                "check": [
                    {
                        "name": "not_part_of_controller",
                        "schema": Schema(
                            {
                                "metadata": {
                                    "ownerReferences": [
                                        Schema(
                                            {
                                                "controller": And(
                                                    bool, lambda x: x == True
                                                ),
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                    },
                ],
            },
        ]
