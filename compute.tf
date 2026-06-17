# =================================================================
# 1. WEB СЕРВЕРЫ
# =================================================================
resource "vkcs_networking_secgroup" "web_sg" {
  name        = "web-sg"
  description = "Security group for web-interface"
}

# ИСПРАВЛЕНО: Убрана русская "с", убраны name/description
resource "vkcs_networking_secgroup_rule" "web_ssh" {
  security_group_id = vkcs_networking_secgroup.web_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = vkcs_networking_secgroup.bastion_sg.id 
}

# ИСПРАВЛЕНО: Восстановлена буква "c" в secgroup, привязано к группе балансировщика
resource "vkcs_networking_secgroup_rule" "web_http" {
  security_group_id = vkcs_networking_secgroup.web_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = vkcs_networking_secgroup.lb_sg.id # Трафик пойдет строго от балансировщика
}

# =================================================================
# 2. БАСТИОН
# =================================================================
resource "vkcs_networking_secgroup" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion"
}

# ИСПРАВЛЕНО: Добавлены все недостающие сетевые параметры и порты для входа на Бастион
resource "vkcs_networking_secgroup_rule" "bastion_ssh" {
  security_group_id = vkcs_networking_secgroup.bastion_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.my_ip # Доступ только с вашего IP
}

# =================================================================
# 3. БАЗА ДАННЫХ (DB)
# =================================================================
resource "vkcs_networking_secgroup" "db_sg" {
  name        = "db-sg"
  description = "Security group for database"
}

resource "vkcs_networking_secgroup_rule" "db_ssh" {
  security_group_id = vkcs_networking_secgroup.db_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = vkcs_networking_secgroup.bastion_sg.id 
}

resource "vkcs_networking_secgroup_rule" "PostgreSQL" {
  security_group_id = vkcs_networking_secgroup.db_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = var.lab2_private # Доступ только из приватной подсети
}

# ИСПРАВЛЕНО: Удален неверный аргумент full_security_groups_control
resource "vkcs_networking_secgroup_rule" "db_egress_http" {
  security_group_id = vkcs_networking_secgroup.db_sg.id
  direction         = "egress"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

# ИСПРАВЛЕНО: Удален неверный аргумент full_security_groups_control
resource "vkcs_networking_secgroup_rule" "db_egress_https" {
  security_group_id = vkcs_networking_secgroup.db_sg.id
  direction         = "egress"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
}

# =================================================================
# 4. БАЛАНСИРОВЩИК (LB)
# =================================================================
resource "vkcs_networking_secgroup" "lb_sg" {
  name        = "lb-sg"
  description = "Security group for web-loadbalancer"
}

resource "vkcs_networking_secgroup_rule" "lb_http" {
  security_group_id = vkcs_networking_secgroup.lb_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "vkcs_networking_secgroup_rule" "lb_https" {
  security_group_id = vkcs_networking_secgroup.lb_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
}

# =================================================================
# 5. Создание бастиона и веб-серверов
# =================================================================

data "vkcs_images_image" "packer_image" {
  name        = var.image_name 
  most_recent = true                  
}

data "vkcs_compute_flavor" "compute_flavor" {
  name = var.flavor # Ищет в облаке тариф с именем "Basic-1-1-10"
}

resource "vkcs_compute_instance" "bastion" {
  name = "bastion-host"
  # AZ and flavor are mandatory
  availability_zone = var.availability_zone 
  flavor_id = data.vkcs_compute_flavor.compute_flavor.id 
  key_pair          = var.key_pair
  #
  block_device {
    source_type      = "image"
    uuid             = data.vkcs_images_image.packer_image.id
    destination_type = "volume"
    volume_size      = 10
    volume_type      = "ceph-ssd"
    delete_on_termination = true
  }
  # Specify at least one network to not depend on project assets
  network {
    port = vkcs_networking_port.bastion_port.id
  }
}
resource "vkcs_compute_instance" "web_server" {
  # Создаем два сервера: "1" и "2"
  for_each = toset(["1", "2"])

  name              = "${var.project_name}-web-${each.key}"
  availability_zone = var.availability_zone 
  key_pair          = var.key_pair
  flavor_id = data.vkcs_compute_flavor.compute_flavor.id 

  block_device {
    source_type           = "image"
    uuid                  = data.vkcs_images_image.packer_image.id # Наш образ из Packer
    destination_type      = "volume"
    volume_size           = 10
    volume_type           = "ceph-ssd"
    delete_on_termination = true
  }

  # ПОДКЛЮЧАЕМ ПОРТ:
  network {
    # Сервер "1" заберет порт "1", сервер "2" заберет порт "2"
    port = vkcs_networking_port.web_server_port[each.key].id
  }
}
