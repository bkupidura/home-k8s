from schema import Schema, And, Or, Optional, Forbidden


validator = [
    {
        "name": "with_multiple_replicas",
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
                "name": "podAntiAffinity_present",
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
        "name": "with_pvc_or_hostpath",
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
                "name": "strategy_recreate",
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
        "name": "without_pvc_or_hostpath",
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
                "name": "strategy_rollingupdate",
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
        "name": "generic",
        "filter": Schema(
            {
                "apiVersion": And(str, lambda x: x == "apps/v1"),
                "kind": And(str, lambda x: x == "Deployment"),
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
                        "spec": {
                            "template": {
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
                "name": "selector_match_labels",
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
                        lambda x: set(x["spec"]["selector"]["matchLabels"].items())
                        <= set(x["spec"]["template"]["metadata"]["labels"].items()),
                    ),
                ),
            },
            {
                "name": "privileged_false",
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
            },
            {
                "name": "runasuser_not_root",
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
            },
            {
                "name": "runasgroup_not_root",
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
                "name": "fsgroup_not_root",
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
                "name": "capabilities_add_missing",
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
            },
            {
                "name": "resources_cpu_present",
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
            },
            {
                "name": "resources_memory_present",
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
            },
            {
                "name": "liveness_probe_present",
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
            },
        ],
    },
]
