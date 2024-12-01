#!/bin/bash

set -e #прерываем дальнейшее выполнение скрипта, если обнаружится ошибка при выполнении кода

printf "external_ip: "

for num in 1
do
terraform output -json instance_group_masters_public_ips | jq -j ".[$num-1]"
done


printf "\nmaster_local_ip: "
for num in 1
do
terraform output -json instance_group_masters_private_ips | jq -j ".[$num-1]"
done

printf "\nproject_folder: "
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ONE_LEVEL_UP="$(dirname "$SCRIPT_DIR")"
printf "$ONE_LEVEL_UP"