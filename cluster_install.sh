#!/bin/bash
#should install "sudo apt install jq"
#should install ansible


set -e

cd terraform
TF_IN_AUTOMATION=1 terraform init
TF_IN_AUTOMATION=1 terraform apply -auto-approve


#создание inventory.ini для Kubespray
printf "Run generate_inventory_k8s.sh\n"
bash ../scripts/generate_inventory_k8s.sh > ../mykubespray/inventory/mycluster/inventory_pw.ini

#создание inventory.ini для Prometheus
printf "Run generate_inventory_prometheus.sh\n"
bash ../scripts/generate_inventory_prometheus.sh > ../inventory/inventory_pw.ini

#запускаем усановку Kubernetes через Kubespray
cd ../mykubespray
export ANSIBLE_HOST_KEY_CHECKING=False
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ./inventory/mycluster/inventory_pw.ini --become --user=alps cluster.yml --private-key=~/.ssh/YaCloudVMs | tee ../playbook_output_Kubernetes_install.log

#запускаем установку Prometheus
cd ../
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ./inventory/inventory_pw.ini --become --user=alps ./playbooks/prometheus_ans.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_prometheus.log

#запускаем установку Docker Registry
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ./inventory/inventory_pw.ini --become --user=alps ./playbooks/docker_registry.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_docker_registry.log