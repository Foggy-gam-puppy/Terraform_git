
data "vkcs_compute_flavor" "db_flavor_uuid" {
  name = var.db_flavor # Ищет текстовое имя "STD2-2-8"
}

# 1. Инстанс СУБД PostgreSQL
resource "vkcs_db_instance" "db" {
  name              = "${var.project_name}-db"
  availability_zone = var.availability_zone
  size              = 20
  volume_type       = "ceph-ssd"
  
  # ИСПРАВЛЕНО: Передаем имя тарифа напрямую, как это принято для DBaaS
  flavor_id         = data.vkcs_compute_flavor.db_flavor_uuid.id 

  datastore {
    type    = "postgresql"
    version = "15"
  }
   
  network {
    subnet_id = vkcs_networking_subnet.private_subnet.id
    
    # ИСПРАВЛЕНО: Привязываем нашу группу безопасности со строгими правилами!
    security_groups = [vkcs_networking_secgroup.db_sg.id]
  }

  depends_on = [vkcs_networking_router_interface.private_interface]
}

# 2. Создание самой базы данных внутри инстанса
resource "vkcs_db_database" "lab2_db" {
  name    = "lab2_db"
  dbms_id = vkcs_db_instance.db.id
}

# 3. Создание пользователя для веб-приложения
resource "vkcs_db_user" "pg_user" { 
  name      = "webapp"
  password  = var.db_password # Секретный пароль из ваших переменных
  dbms_id   = vkcs_db_instance.db.id
  databases = [vkcs_db_database.lab2_db.name]

  depends_on = [vkcs_db_database.lab2_db]
}
