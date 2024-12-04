# Variables

#лучше тащить id сразу из облака, раз alps уже создан
#variable "alps_service_account_id" {
#  description = "The ID of the alps service account"
#  type        = string
#}

#лучше тащить id сразу из облака, раз alps уже создан
data "yandex_iam_service_account" "alps" {
  name = "alps"
}

#variable "yc_token" {
#  type = string
#  description = "Yandex Cloud API key"
#}
#
#variable "yc_cloud_id" {
#  type = string
#  description = "Yandex Cloud id"
#}
#
#variable "yc_folder_id" {
#  type = string
#  description = "Yandex Cloud folder id"
#}

# Provider

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
}

#provider "yandex" {
#  token     = var.yc_token
#  cloud_id  = var.yc_cloud_id
#  folder_id = var.yc_folder_id
#}

# Network

resource "yandex_vpc_network" "k8s-network" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "k8s-subnet" {
  name           = "k8s-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  depends_on = [
    yandex_vpc_network.k8s-network,
  ]
}

#resource "yandex_vpc_subnet" "k8s-subnet-2" {
#  name           = "k8s-subnet-2"
#  zone           = "ru-central1-b"
#  network_id     = yandex_vpc_network.k8s-network.id
#  v4_cidr_blocks = ["192.168.20.0/24"]
#  depends_on = [
#    yandex_vpc_network.k8s-network,
#  ]
#}

#resource "yandex_vpc_subnet" "k8s-subnet-3" {
#  name           = "k8s-subnet-3"
#  zone           = "ru-central1-c"
#  network_id     = yandex_vpc_network.k8s-network.id
#  v4_cidr_blocks = ["192.168.30.0/24"]
#  depends_on = [
#    yandex_vpc_network.k8s-network,
#  ]
#}

# Service accounts (не нужно, он настроен руками)

#resource "yandex_iam_service_account" "admin" {
#  name = "alps"
#}
#
#resource "yandex_resourcemanager_folder_iam_binding" "editor" {
#  folder_id = var.yc_folder_id
#  role = "editor"
#  members = [
#    "serviceAccount:${yandex_iam_service_account.admin.id}",
#  ]
#  depends_on = [
#    yandex_iam_service_account.admin,
#  ]
#}
#
#resource "yandex_iam_service_account_static_access_key" "static-access-key" {
#  service_account_id = yandex_iam_service_account.admin.id
#  depends_on = [
#    yandex_iam_service_account.admin,
#  ]
#}

# Compute instance group for masters

resource "yandex_compute_instance_group" "k8s-masters" {
  name               = "k8s-masters"
  #service_account_id = yandex_iam_service_account.admin.id
  service_account_id = data.yandex_iam_service_account.alps.id
  depends_on = [
    #yandex_iam_service_account.admin,
    #yandex_resourcemanager_folder_iam_binding.editor,
    yandex_vpc_network.k8s-network,
    yandex_vpc_subnet.k8s-subnet #,
    #yandex_vpc_subnet.k8s-subnet-2,
    #yandex_vpc_subnet.k8s-subnet-3,
  ]
  
  # Шаблон экземпляра, к которому принадлежит группа экземпляров.
  instance_template {

    # Имя виртуальных машин, создаваемых Instance Groups
    name = "master-{instance.index}"

    # Ресурсы, которые будут выделены для создания виртуальных машин в Instance Groups
    resources {
      cores  = 4
      memory = 8
      core_fraction = 100 # Базовый уровень производительности vCPU. https://cloud.yandex.ru/docs/compute/concepts/performance-levels
    }

    # Загрузочный диск в виртуальных машинах в Instance Groups
    boot_disk {
      initialize_params {
        #image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 20.04 LTS
        image_id="fd874d4jo8jbroqs6d7i" #Ubuntu 22.04 LTS
        size     = 40
        type     = "network-ssd"
        #type     = "network-hdd"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.k8s-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet.id #,
        #yandex_vpc_subnet.k8s-subnet-2.id,
        #yandex_vpc_subnet.k8s-subnet-3.id,
      ]
      # Флаг nat true указывает что виртуалкам будет предоставлен публичный IP адрес.
      nat = true
    }

    #metadata = {
    #  ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    #}
    metadata = {
      user-data = "${file("ya_cloud_user_metadata.yml")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    zones = [
      "ru-central1-a" #,
      #"ru-central1-b",
      #"ru-central1-c",
    ]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }
}

# Compute instance group for workers

resource "yandex_compute_instance_group" "k8s-workers" {
  name               = "k8s-workers"
  #service_account_id = yandex_iam_service_account.admin.id
  service_account_id = data.yandex_iam_service_account.alps.id
  depends_on = [
    #yandex_iam_service_account.admin,
    #yandex_resourcemanager_folder_iam_binding.editor,
    #yandex_vpc_network.k8s-network,
    yandex_vpc_subnet.k8s-subnet #,
    #yandex_vpc_subnet.k8s-subnet-2,
    #yandex_vpc_subnet.k8s-subnet-3,
  ]

  instance_template {

    name = "worker-{instance.index}"

    resources {
      cores  = 4
      memory = 8
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        #image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 20.04 LTS
        image_id="fd874d4jo8jbroqs6d7i" #Ubuntu 22.04 LTS
        size     = 30
        type     = "network-hdd"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.k8s-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet.id #,
        #yandex_vpc_subnet.k8s-subnet-2.id,
        #yandex_vpc_subnet.k8s-subnet-3.id,
      ]
      # Флаг nat true указывает что виртуалкам будет предоставлен публичный IP адрес.
      nat = true
    }

    #metadata = {
    #  ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    #}
    metadata = {
      user-data = "${file("ya_cloud_user_metadata.yml")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    zones = [
      "ru-central1-a" #,
      #"ru-central1-b",
      #"ru-central1-c",
    ]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }
}

# Compute instance group for ingresses (не применяем)

#resource "yandex_compute_instance_group" "k8s-ingresses" {
#  name               = "k8s-ingresses"
#  service_account_id = yandex_iam_service_account.admin.id
#  depends_on = [
#    yandex_iam_service_account.admin,
#    yandex_resourcemanager_folder_iam_binding.editor,
#    yandex_vpc_network.k8s-network,
#    yandex_vpc_subnet.k8s-subnet,
#    yandex_vpc_subnet.k8s-subnet-2,
#    yandex_vpc_subnet.k8s-subnet-3,
#  ]
#
#  load_balancer {
#    target_group_name = "k8s-ingresses"
#  }
#
#  instance_template {
#
#    name = "ingress-{instance.index}"
#
#    resources {
#      cores  = 2
#      memory = 2
#      core_fraction = 20
#    }
#
#    boot_disk {
#      initialize_params {
#        image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 20.04 LTS
#        size     = 10
#        type     = "network-hdd"
#      }
#    }
#
#    network_interface {
#      network_id = yandex_vpc_network.k8s-network.id
#      subnet_ids = [
#        yandex_vpc_subnet.k8s-subnet.id,
#        yandex_vpc_subnet.k8s-subnet-2.id,
#        yandex_vpc_subnet.k8s-subnet-3.id,
#      ]
#      # Флаг nat true указывает что виртуалкам будет предоставлен публичный IP адрес.
#      nat = true
#    }
#
#    metadata = {
#      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
#    }
#    network_settings {
#      type = "STANDARD"
#    }
#  }
#
#  scale_policy {
#    fixed_scale {
#      size = 2
#    }
#  }
#
#  allocation_policy {
#    zones = [
#      "ru-central1-a",
#      "ru-central1-b",
#      "ru-central1-c",
#    ]
#  }
#
#  deploy_policy {
#    max_unavailable = 2
#    max_creating    = 2
#    max_expansion   = 2
#    max_deleting    = 2
#  }
#}

# Load balancer for ingresses (не применяем)

#resource "yandex_lb_network_load_balancer" "k8s-load-balancer" {
#  name = "k8s-load-balancer"
#  depends_on = [
#    yandex_compute_instance_group.k8s-ingresses,
#  ]
#
#  listener {
#    name = "my-listener"
#    port = 80
#    external_address_spec {
#      ip_version = "ipv4"
#    }
#  }
#
#  attached_target_group {
#    target_group_id = yandex_compute_instance_group.k8s-ingresses.load_balancer.0.target_group_id
#    healthcheck {
#      name = "http"
#      http_options {
#        port = 80
#        path = "/healthz"
#      }
#    }
#  }
#}

# Backet for storing cluster backups (не применяем)

#resource "yandex_storage_bucket" "backup-backet-apatsev" {
#  bucket = "backup-backet-apatsev"
#  force_destroy = true
#  access_key = yandex_iam_service_account_static_access_key.static-access-key.access_key
#  secret_key = yandex_iam_service_account_static_access_key.static-access-key.secret_key
#  depends_on = [
#    yandex_iam_service_account_static_access_key.static-access-key
#  ]
#}

#creating server for monitoring 
data "yandex_compute_image" "my_image" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "boot-disk" {
  name     = "boot-disk"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = 40
  image_id = data.yandex_compute_image.my_image.id
}

resource "yandex_compute_instance" "srv" {
  name = "srv"
  hostname = "srv"
  zone     = "ru-central1-a"
  description = "Server for monitoring"

  resources {
    cores  = 4
    memory = 8
	core_fraction = 100 #Гарантированная доля vCPU - 100%
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.k8s-subnet.id
    nat       = true
  }

  metadata = {
    user-data = "${file("ya_cloud_user_metadata.yml")}"
  }
  
  scheduling_policy {
    preemptible = false  #ВМ прерыраемая
  }
}

# Output values 

output "instance_group_masters_public_ips" {
  description = "Public IP addresses for master-nodes"
  value = yandex_compute_instance_group.k8s-masters.instances.*.network_interface.0.nat_ip_address
}

output "instance_group_masters_private_ips" {
  description = "Private IP addresses for master-nodes"
  value = yandex_compute_instance_group.k8s-masters.instances.*.network_interface.0.ip_address
}

output "instance_group_workers_public_ips" {
  description = "Public IP addresses for worder-nodes"
  value = yandex_compute_instance_group.k8s-workers.instances.*.network_interface.0.nat_ip_address
}

output "instance_group_workers_private_ips" {
  description = "Private IP addresses for worker-nodes"
  value = yandex_compute_instance_group.k8s-workers.instances.*.network_interface.0.ip_address
}

output "external_ip_address_srv" {
  value = yandex_compute_instance.srv.network_interface.0.nat_ip_address
}

output "internal_ip_address_srv" {
  value = yandex_compute_instance.srv.network_interface.0.ip_address
}

#output "instance_group_ingresses_public_ips" {
#  description = "Public IP addresses for ingress-nodes"
#  value = yandex_compute_instance_group.k8s-ingresses.instances.*.network_interface.0.nat_ip_address
#}
#
#output "instance_group_ingresses_private_ips" {
#  description = "Private IP addresses for ingress-nodes"
#  value = yandex_compute_instance_group.k8s-ingresses.instances.*.network_interface.0.ip_address
#}
#
#output "load_balancer_public_ip" {
#  description = "Public IP address of load balancer"
#  value = yandex_lb_network_load_balancer.k8s-load-balancer.listener.*.external_address_spec[0].*.address
#}
#
#output "static-key-access-key" {
#  description = "Access key for admin user"
#  value = yandex_iam_service_account_static_access_key.static-access-key.access_key
#}
#
#output "static-key-secret-key" {
#  description = "Secret key for admin user"
#  value = yandex_iam_service_account_static_access_key.static-access-key.secret_key
#  sensitive = true
#}
