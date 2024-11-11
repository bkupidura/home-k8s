from schema import Schema, And, Or, Optional, Forbidden


validator = [
    {
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "apps/v1"),
                "kind": And(str, lambda x: x == "Deployment"),
                "spec": {
                    "replicas": And(int, lambda x: x > 1),
                },
            },
            ignore_extra_keys=True,
        ),
        "validators": [
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "affinity": {
                                        "podAntiAffinity": dict,
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
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "apps/v1"),
                "kind": And(str, lambda x: x == "Deployment"),
                "spec": {
                    "template": {
                        "spec": {
                            "volumes": [
                                Schema(
                                    {
                                        "persistentVolumeClaim": dict,
                                    },
                                    ignore_extra_keys=True,
                                ),
                                Schema(
                                    {
                                        "hostPath": dict,
                                    },
                                    ignore_extra_keys=True,
                                ),
                            ],
                        },
                    },
                },
            },
            ignore_extra_keys=True,
        ),
        "validators": [
            {
                "schema": Schema(
                    {
                        "spec": {
                            "strategy": {
                                "type": And(str, lambda x: x == "Recreate"),
                            },
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
                "apiVersion": And(str, lambda x: x == "apps/v1"),
                "kind": And(str, lambda x: x == "Deployment"),
                "spec": {
                    "template": {
                        "spec": {
                            "volumes": [
                                Schema(
                                    {
                                        Forbidden("persistentVolumeClaim"): dict,
                                        Forbidden("hostPath"): dict,
                                    },
                                    ignore_extra_keys=True,
                                ),
                            ],
                        },
                    },
                },
            },
            ignore_extra_keys=True,
        ),
        "validators": [
            {
                "schema": Schema(
                    {
                        "spec": {
                            "strategy": {
                                "type": And(str, lambda x: x == "RollingUpdate"),
                            },
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
                "apiVersion": And(str, lambda x: x == "apps/v1"),
                "kind": And(str, lambda x: x == "Deployment"),
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
                        "spec": {
                            "template": {
                                "metadata": {
                                    "labels": {
                                        "app.kubernetes.io/name": str,
                                        "name": str,
                                    },
                                },
                                "spec": {
                                    "containers": [
                                        {
                                            "image": And(
                                                str, lambda x: not x.endswith(":latest")
                                            ),
                                            "imagePullPolicy": And(
                                                str, lambda x: x == "IfNotPresent"
                                            ),
                                        },
                                    ],
                                },
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
            },
            {
                "schema": Schema(
                    And(
                        Schema(
                            {
                                "spec": {
                                    "selector": {"matchLabels": dict},
                                    "template": {"metadata": {"labels": dict}},
                                },
                            },
                            ignore_extra_keys=True,
                        ),
                        lambda x: x["spec"]["selector"]["matchLabels"].items()
                        == x["spec"]["template"]["metadata"]["labels"].items(),
                    ),
                )
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                Optional("securityContext"): {
                                                    Optional("privileged"): And(
                                                        bool, lambda x: x == False
                                                    )
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "exceptions": [
                    "smart-home/zigbee2mqtt",
                    "smart-home/sms-gammu",
                    "smart-home/recorder",
                    "home-infra/network-ups-tools",
                    "home-infra/debugpod",
                ],
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                Optional("securityContext"): {
                                                    Optional("runAsUser"): And(
                                                        int, lambda x: x != 0
                                                    ),
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "exceptions": ["home-infra/debugpod"],
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                Optional("securityContext"): {
                                                    Optional("runAsGroup"): And(
                                                        int, lambda x: x != 0
                                                    ),
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                Optional("securityContext"): {
                                                    Optional("fsGroup"): And(
                                                        int, lambda x: x != 0
                                                    ),
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                Optional("securityContext"): {
                                                    Optional("capabilities"): {
                                                        Forbidden("add"): [str],
                                                    }
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "exceptions": ["kube-system/coredns"],
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                "resources": {
                                                    Optional("requests"): {
                                                        Optional("cpu"): Or(
                                                            int, float, str
                                                        ),
                                                    },
                                                    Optional("limits"): {
                                                        Optional("cpu"): Or(
                                                            int, float, str
                                                        ),
                                                    },
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "exceptions": ["home-infra/debugpod", "smart-home/esphome"],
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                "resources": {
                                                    Optional("requests"): {
                                                        Optional("memory"): str,
                                                    },
                                                    "limits": {
                                                        "memory": str,
                                                    },
                                                }
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "exceptions": ["home-infra/debugpod", "smart-home/esphome"],
            },
            {
                "schema": Schema(
                    {
                        "spec": {
                            "template": {
                                "spec": {
                                    "containers": [
                                        Schema(
                                            {
                                                "livenessProbe": dict,
                                            },
                                            ignore_extra_keys=True,
                                        ),
                                    ],
                                }
                            },
                        },
                    },
                    ignore_extra_keys=True,
                ),
                "exceptions": ["home-infra/debugpod"],
            },
        ],
    },
]
