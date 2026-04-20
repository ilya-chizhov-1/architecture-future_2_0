# =====================================================================
# Перед запуском terraform apply подставить реальные значения:
#   - cloud_id / folder_id взять из консоли Yandex Cloud
#   - service_account_key_file - путь к JSON-ключу сервисного аккаунта
#   - ssh_public_key_file - путь к публичному SSH-ключу (абсолютный)
#   - admin_cidr - ваш публичный IP/32 вместо 0.0.0.0/0 для безопасности
# =====================================================================

cloud_id                 = "REPLACE_WITH_YOUR_CLOUD_ID"
folder_id                = "REPLACE_WITH_YOUR_FOLDER_ID"
service_account_key_file = "./sa-key.json"

zone    = "ru-central1-a"
project = "future20"

public_subnet_cidr  = "10.10.1.0/24"
private_subnet_cidr = "10.10.2.0/24"
admin_cidr          = "0.0.0.0/0"

ssh_public_key_file = "REPLACE_WITH_PATH_TO_YOUR_PUBLIC_KEY"

image_family      = "ubuntu-2204-lts"
boot_disk_size    = 20
db_data_disk_size = 50

bastion_cores  = 2
bastion_memory = 2
app_cores      = 2
app_memory     = 4
db_cores       = 2
db_memory      = 4
