from schema import SchemaError


class ValidatorBase(object):
    def __init__(self, conf):
        self.conf = conf

    def run_checks(self, manifest):
        errors = list()
        for validator in self.validators:
            if validator["name"] not in self.conf.keys():
                continue

            try:
                validator["filter"].validate(manifest)
            except SchemaError:
                continue

            resource_full_name = f"{manifest['metadata'].get('namespace')}/{manifest['metadata'].get('name')}"
            validator_config = self.conf[validator["name"]]

            if validator_config is None:
                validator_config = dict()

            for check in validator["check"]:
                check_config = validator_config.get(check["name"], dict())

                if resource_full_name in check_config.get("skip", list()):
                    continue

                try:
                    check["schema"].validate(manifest)
                except SchemaError as e:
                    errors.append(
                        {
                            "check": f"{self.name}/{validator['name']}/{check['name']}",
                            "errors": e.autos,
                        }
                    )
        return errors
