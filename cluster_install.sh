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

#запускаем установку Docker Registry
printf "\e[32mЗапускаем docker_registry.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/docker_registry.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_docker_registry.log

#установка конфигурационных файлов containerd
printf "\e[32mЗапускаем containerd.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/containerd.yml --private-key=~/.ssh/YaCloudVMs

#установка 
printf "\e[32mЗапускаем fluentd_install.yaml\e[0m\n"
ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/fluentd_install.yml --private-key=~/.ssh/YaCloudVMs


printf "\e[32mЗапускаем change_alerts.sh. Подготавливаем конфигурацию для правил alert.\e[0m\n"
./scripts/change_alerts.sh

#запускаем установку Prometheus,Node Exporters
printf "\e[32mЗапускаем prometheus_ans.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/prometheus_ans.yml --private-key=~/.ssh/YaCloudVMs | tee playbook_output_prometheus.log

printf "\e[32mЗапускаем blackbox.yaml\e[0m\n"
ansible-playbook -i inventory_pw.ini --become --user=alps playbooks/blackbox.yml --private-key=~/.ssh/YaCloudVMs

#установка Grafana (ломает машину через некоторое время)
printf "\e[32mЗапускаем grafana_install.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/grafana_install.yml --private-key=~/.ssh/YaCloudVMs

#настройки для sftp 
printf "\e[32mЗапускаем set_sftp.yml\e[0m\n"
ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory_pw.ini --become --user=alps ./playbooks/set_sftp.yml --private-key=~/.ssh/YaCloudVMs


printf "\e[32mСкрипт выполнен, проверяй!\e[0m\n"