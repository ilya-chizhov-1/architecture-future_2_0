output "vpc_id" {
  description = "Идентификатор VPC"
  value       = yandex_vpc_network.main.id
}

output "public_subnet_id" {
  description = "Идентификатор публичной подсети"
  value       = yandex_vpc_subnet.public.id
}

output "private_subnet_id" {
  description = "Идентификатор приватной подсети"
  value       = yandex_vpc_subnet.private.id
}

output "nat_gateway_id" {
  description = "Идентификатор NAT-шлюза"
  value       = yandex_vpc_gateway.nat.id
}

output "bastion_public_ip" {
  description = "Публичный IP bastion-хоста"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "bastion_internal_ip" {
  description = "Внутренний IP bastion"
  value       = yandex_compute_instance.bastion.network_interface[0].ip_address
}

output "app_internal_ip" {
  description = "Внутренний IP app-сервера"
  value       = yandex_compute_instance.app.network_interface[0].ip_address
}

output "db_internal_ip" {
  description = "Внутренний IP db-сервера"
  value       = yandex_compute_instance.db.network_interface[0].ip_address
}

output "db_data_disk_id" {
  description = "Идентификатор диска данных БД"
  value       = yandex_compute_disk.db_data.id
}

output "ssh_to_bastion" {
  description = "Готовая команда для подключения к bastion"
  value       = "ssh ubuntu@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address}"
}

output "ssh_to_app_via_bastion" {
  description = "Команда для подключения к app через bastion"
  value       = "ssh -J ubuntu@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} ubuntu@${yandex_compute_instance.app.network_interface[0].ip_address}"
}

output "ssh_to_db_via_bastion" {
  description = "Команда для подключения к db через bastion"
  value       = "ssh -J ubuntu@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} ubuntu@${yandex_compute_instance.db.network_interface[0].ip_address}"
}
