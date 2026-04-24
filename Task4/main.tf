terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# Базовый образ для всех ВМ
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

# ============================================================================
# Сеть: VPC + публичная и приватная подсети
# ============================================================================

resource "yandex_vpc_network" "main" {
  name        = "${var.project}-network"
  description = "Основная VPC для учебного проекта «Будущее 2.0»"
}

resource "yandex_vpc_subnet" "public" {
  name           = "${var.project}-subnet-public"
  description    = "Публичная подсеть: bastion, точки входа"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

resource "yandex_vpc_subnet" "private" {
  name           = "${var.project}-subnet-private"
  description    = "Приватная подсеть: app, db; egress через NAT-gateway"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.private.id
}

# ============================================================================
# NAT-шлюз для исходящего трафика приватной подсети
# ============================================================================

resource "yandex_vpc_gateway" "nat" {
  name = "${var.project}-nat-gateway"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name        = "${var.project}-rt-private"
  description = "Маршрут по умолчанию на NAT-gateway для приватной подсети"
  network_id  = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

# ============================================================================
# Группы безопасности: bastion, app, db
# ============================================================================

resource "yandex_vpc_security_group" "bastion" {
  name        = "${var.project}-sg-bastion"
  description = "SSH-доступ к bastion только с доверенного CIDR"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
    description    = "SSH с рабочей станции администратора"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Исходящий трафик наружу"
  }
}

resource "yandex_vpc_security_group" "app" {
  name        = "${var.project}-sg-app"
  description = "Приложение: SSH только с bastion, HTTP из публичной подсети"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
    description       = "SSH только с bastion"
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = [var.public_subnet_cidr]
    description    = "HTTP из публичной подсети (будущий балансировщик)"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Исходящий через NAT"
  }
}

resource "yandex_vpc_security_group" "db" {
  name        = "${var.project}-sg-db"
  description = "База данных: Postgres только с app, SSH только с bastion"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    port              = 5432
    security_group_id = yandex_vpc_security_group.app.id
    description       = "Postgres только с app"
  }

  ingress {
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
    description       = "SSH только с bastion"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Исходящий для обновлений пакетов через NAT"
  }
}

# ============================================================================
# Отдельный диск под данные БД (отделён от boot-диска)
# ============================================================================

resource "yandex_compute_disk" "db_data" {
  name        = "${var.project}-db-data"
  description = "Персистентный диск для данных БД (отделён от boot)"
  type        = "network-ssd"
  zone        = var.zone
  size        = var.db_data_disk_size
}

# ============================================================================
# Виртуальные машины: bastion, app, db
# ============================================================================

resource "yandex_compute_instance" "bastion" {
  name                      = "${var.project}-bastion"
  hostname                  = "bastion"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores  = var.bastion_cores
    memory = var.bastion_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.ssh_public_key_file)}"
    serial-port-enable = "1"
  }
}

resource "yandex_compute_instance" "app" {
  name                      = "${var.project}-app"
  hostname                  = "app"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores  = var.app_cores
    memory = var.app_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.app.id]
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.ssh_public_key_file)}"
    serial-port-enable = "1"
  }
}

resource "yandex_compute_instance" "db" {
  name                      = "${var.project}-db"
  hostname                  = "db"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores  = var.db_cores
    memory = var.db_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size
      type     = "network-ssd"
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.db_data.id
    device_name = "data"
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.db.id]
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.ssh_public_key_file)}"
    serial-port-enable = "1"
  }
}
