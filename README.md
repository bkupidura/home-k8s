## Install cli
`brew install git`  
`brew install pip`  
`brew install kubernetes-cli`  
`brew install helm`  
`pip3 install "jinja2-cli[yaml]"`  
`pip3 install jinja2-ansible-filters`  

## data/config.yaml file
Encrypt file `gpg --symmetric data/config.yaml`

## Cluster deployment from scratch

##### Deploy K3Os on master from ISO

##### Upload config to master
`./scripts/render-template.sh k3shome/k3os/server.yaml.jinja2 k3s-bravo`

##### Configure networking on master
`connmanctl config ethernet_d8cb8ad15025_cable --ipv6 off --nameservers 1.1.1.1 8.8.8.8 --timeservers 0.pl.pool.ntp.org 1.pl.pool.ntp.org --ipv4 dhcp`

##### Update data/config.yaml.gpg with K3S_TOKEN
Token can be found on master in `/var/lib/rancher/k3s/server/node-token`

##### Reboot master

##### Deploy K3Os on workers from ISO
##### Upload config to worker
##### Configure networking on worker
##### Reboot worker

##### Copy /etc/rancher/k3s/k3s.yaml
Copy `/etc/rancher/k3s/k3s.yaml` from any node.  
`export KUBECONFIG=~/home-k8s/k3s-access.yaml`

## Render manifests
`./scripts/render-template.sh`

## Generate and upload statics
`./scripts/generate-statics.sh`

## Restore volumes from backup
`kubectl create job --from=cronjob/home-assistant-restic-restore home-assistant-restore -n home-infra`

## Deploy
`kubectl -f k3shome/manifest/stage...`
