# 1. Публичный IP балансировщика нагрузки (Берется автоматически из Floating IP)
output "load_balancer_public_ip" {
  value       = vkcs_networking_floatingip.fip_lb.address
  description = "Public IP-address of Load Balancer"
}

# 2. Публичный IP Бастиона (Берется автоматически из Floating IP)
output "bastion_public_ip" {
  value       = vkcs_networking_floatingip.fip_bastion.address
  description = "Real public IP for bastion SSH connection"
}

# 3. Приватные IP-адреса веб-серверов (Уже в приватной подсети 10.0.2.x)
output "web_servers_private_ips" {
  value = {
    for name, server in vkcs_compute_instance.web_server : name => server.network[0].fixed_ip_v4
  }
  description = "IP web-servers in private subnet"
}

# 4. Хост (Приватный IP) базы данных PostgreSQL
output "database_private_ip" {
  value       = vkcs_db_instance.db.ip
  description = "Internal IP (Host) for db PostgreSQL"
}

# 5. Имя базы данных 
output "database_name" {
  value       = vkcs_db_database.lab2_db.name
  description = "Name of the PostgreSQL database"
}
