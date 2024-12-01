#!/bin/bash
#should install "sudo apt install jq"
#should install ansible


set -e

cd terraform
TF_IN_AUTOMATION=1 terraform init
TF_IN_AUTOMATION=1 terraform apply -auto-approve


#создание inventory.ini для Kubespray
printf "\e[32mRun generate_inventory_k8s.sh\e[0m\n"
bash ../scripts/generate_inventory_k8s.sh > ../inventory_pw.ini

printf "\e[32mRun generate_vars.sh\e[0m\n"
bash ../scripts/generate_vars.sh > ../vars/vars.yml

export ANSIBLE_HOST_KEY_CHECKING=False

cd ../
printf "\e[32mЗапускаем wait-for-server-to-start.yml\e[0m\n"
ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/wait-for-server-to-start.yml --private-key=~/.ssh/YaCloudVMs

printf "\e[32mЗапускаем kube-dependencies.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/kube-dependencies.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_kube-dependencies.log

printf "\e[32mЗапускаем master.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/master.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_master.log

printf "\e[32mЗапускаем workers.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/workers.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_workers.log

printf "\e[32mЗапускаем fetch_admin_conf.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/fetch_admin_conf.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_fetch_admin_conf.log

##создание inventory.ini для Prometheus
#printf "Run generate_inventory_prometheus.sh\n"
#bash ../scripts/generate_inventory_prometheus.sh > ../inventory/inventory_pw.ini
#
##запускаем усановку Kubernetes через Kubespray
#cd ../mykubespray
#export ANSIBLE_HOST_KEY_CHECKING=False
#ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ./inventory/mycluster/inventory_pw.ini --become --user=alps cluster.yml --private-key=~/.ssh/YaCloudVMs | tee ../playbook_output_Kubernetes_install.log
#


#запускаем установку Prometheus,Node Exporters
printf "\e[32mЗапускаем prometheus_ans.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/prometheus_ans.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_prometheus.log

#запускаем установку Docker Registry
printf "\e[32mЗапускаем docker_registry.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/docker_registry.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_docker_registry.log

printf "\e[32mСкрипт выполнен, проверяй!\e[0m\n"