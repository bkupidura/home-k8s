## Install cli
`brew install git`  
`brew install python3`  
`brew install kubernetes-cli`  
`brew install helm`  
`brew install esolitos/ipa/sshpass`  
`pip3 install ansible`  


## Cluster deployment from scratch

##### Deploy Ubuntu server on all nodes

##### Update ansible/inventory 

##### Run ansible
`./scripts/run_ansible.sh -r configure_nodes.yaml`
`./scripts/run_ansible.sh -r install_k3s.yaml -e operation=deploy`

##### Source kube-config
`export KUBECONFIG=kube-config.yaml`

## Render manifests
`./scripts/run_ansible.sh -r render_manifests.yaml`

## Restore volumes from backup
`kubectl create job --from=cronjob/home-assistant-restic-restore home-assistant-restore -n home-infra`

## Deploy
`kubectl -f manifests/stage...`

## Show ansible variables
`./scripts/run_ansible.sh -s all`

## Show ansible facts
`./scripts/run_ansible.sh -f all`
