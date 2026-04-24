variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "service_account_key_file" {
  description = "Путь к JSON-ключу сервисного аккаунта Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности Yandex Cloud"
  type        = string
  default     = "ru-central1-a"
}

variable "project" {
  description = "Префикс для имён всех ресурсов"
  type        = string
  default     = "future20"
}

# ==== Сеть ====

variable "public_subnet_cidr" {
  description = "CIDR публичной подсети"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR приватной подсети"
  type        = string
  default     = "10.10.2.0/24"
}

variable "admin_cidr" {
  description = "CIDR, с которого разрешён SSH на bastion. На проде заменить на адрес администратора"
  type        = string
  default     = "0.0.0.0/0"
}

# ==== SSH и образ ====

variable "ssh_public_key_file" {
  description = "Путь к файлу с публичным SSH-ключом (абсолютный). Содержимое подставляется в metadata ВМ как ssh-keys"
  type        = string
}

variable "image_family" {
  description = "Семейство образа ОС"
  type        = string
  default     = "ubuntu-2204-lts"
}

# ==== Диски ====

variable "boot_disk_size" {
  description = "Размер boot-диска, ГБ"
  type        = number
  default     = 20
}

variable "db_data_disk_size" {
  description = "Размер диска данных БД, ГБ"
  type        = number
  default     = 50
}

# ==== Размеры ВМ ====

variable "bastion_cores" {
  description = "Количество vCPU для bastion"
  type        = number
  default     = 2
}

variable "bastion_memory" {
  description = "Объём памяти bastion, ГБ"
  type        = number
  default     = 2
}

variable "app_cores" {
  description = "Количество vCPU для app"
  type        = number
  default     = 2
}

variable "app_memory" {
  description = "Объём памяти app, ГБ"
  type        = number
  default     = 4
}

variable "db_cores" {
  description = "Количество vCPU для db"
  type        = number
  default     = 2
}

variable "db_memory" {
  description = "Объём памяти db, ГБ"
  type        = number
  default     = 4
}
