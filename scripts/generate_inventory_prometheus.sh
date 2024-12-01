#!/bin/bash

set -e #прерываем дальнейшее выполнение скрипта, если обнаружится ошибка при выполнении кода

printf "[prometheus_server]\n"
terraform output -json external_ip_address_srv | jq -j "."
printf "\n\n"


printf "[node_exporters]\n"
for num in 1
do
terraform output -json instance_group_masters_public_ips | jq -j ".[$num-1]"
printf "\n"
done


for num in 1
do
terraform output -json instance_group_workers_public_ips | jq -j ".[$num-1]"
printf "\n\n"
done

printf "[srv]\n"
terraform output -json external_ip_address_srv | jq -j "."
printf "\n"