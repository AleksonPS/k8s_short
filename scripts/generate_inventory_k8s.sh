#!/bin/bash

set -e #прерываем дальнейшее выполнение скрипта, если обнаружится ошибка при выполнении кода

printf "[all]\n"

for num in 1
do
printf "master-$num   ansible_host="
terraform output -json instance_group_masters_public_ips | jq -j ".[$num-1]" #should install "sudo apt  install jq"
#printf "   ip="
#terraform output -json instance_group_masters_private_ips | jq -j ".[$num-1]"
#printf "   etcd_member_name=etcd-$num\n"
printf "\n"
done

for num in 1
do
printf "worker-$num   ansible_host="
terraform output -json instance_group_workers_public_ips | jq -j ".[$num-1]"
#printf "   ip="
#terraform output -json instance_group_workers_private_ips | jq -j ".[$num-1]"
printf "\n"
done

printf "srv   ansible_host="
terraform output -json external_ip_address_srv | jq -j "."
printf "\n\n"


#printf "\n[all:vars]\n"
#printf "supplementary_addresses_in_ssl_keys='[\""
#terraform output -json instance_group_masters_public_ips | jq -j ".[0]"
##printf "\",\""
##terraform output -json instance_group_workers_public_ips | jq -j ".[0]"
#printf "\"]'\n\n"


cat << EOF
[master]
master-1

[workers]
worker-1

[srvserv]
srv

[node_exporters]
master-1
worker-1

[all:vars]
#ansible_python_interpreter=/usr/bin/python3
ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_ssh_private_key_file=~/.ssh/YaCloudVMs
ansible_user=alps
EOF
