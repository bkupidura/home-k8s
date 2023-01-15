## Install cli
```
brew install git
brew install python3
brew install kubernetes-cli
brew install tanka
brew install jsonnet-bundler
brew install esolitos/ipa/sshpass
brew install sops
pip3 install ansible
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
jb install github.com/jsonnet-libs/k8s-libsonnet/1.24@main
./scripts/tanka apply tanka/environments/prod/
```

## Show ansible variables
`./scripts/run_ansible.sh -s all`

## Show ansible facts
`./scripts/run_ansible.sh -f all`
