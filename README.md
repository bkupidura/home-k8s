## Install cli

```
brew install git
brew install python3
brew install kubernetes-cli
brew install tanka
brew install jsonnet-bundler
brew install esolitos/ipa/sshpass
brew install sops
pip3 install ansible mitogen
```

## Cluster deployment from scratch

##### Deploy Ubuntu server on all nodes

##### Update ansible/inventory

##### Run ansible

```
./scripts/run_ansible.sh -r configure_nodes.yaml
./scripts/run_ansible.sh -r install_k8s.yaml -e operation=deploy
```

##### Source kube-config

`export KUBECONFIG=kube-config.yaml`

## Deploy k8s workload

```
jb install github.com/jsonnet-libs/k8s-libsonnet/1.28@main
./scripts/tanka apply tanka/environments/prod/
```

## Show ansible variables

`./scripts/run_ansible.sh -s all`

## Show ansible facts

`./scripts/run_ansible.sh -f all`

## Validate all manifests

```
python3 -mvenv scripts/validate/venv
source scripts/validate/venv/bin/activate
pip3 install -r scripts/validate/requirements.txt
sops exec-file scripts/validate/config.yaml "kubectl get deployment,daemonset,service,cronjob,ingressroute,statefulset,pod -A -o yaml | python3 scripts/validate/validate.py -c {}"
```
