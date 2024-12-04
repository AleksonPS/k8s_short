#!/bin/bash

# Получаем путь к текущему скрипту, чтобы правильно ссылаться на файлы
script_dir=$(dirname "$(realpath "$0")")


inventory_file="$script_dir/../inventory_pw.ini"
template_file="$script_dir/../templates/alert_rules.template"
output_file="$script_dir/../templates/alert_rules.yml"
#для prometheus
template_file_p="$script_dir/../templates/prometheus.template"
output_file_p="$script_dir/../templates/prometheus.yml"

# Извлекаем IP-адрес из файла inventory_pw.ini
master_ip=$(grep -oP 'master-1\s+ansible_host=\K[\d.]+' "$inventory_file")

# Проверяем, что IP был найден
if [ -z "$master_ip" ]; then
  echo "Ошибка: не найден IP-адрес в файле inventory."
  exit 1
fi

# Заменяем {master_ip} 
sed "s/{master_ip}/$master_ip/g" "$template_file" > "$output_file"
sed "s/{master_ip}/$master_ip/g" "$template_file_p" > "$output_file_p"

echo "Файлы alert_rules.yml и prometheus.yml обновлены на IP: $master_ip"
