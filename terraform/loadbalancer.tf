# 1. Сам Балансировщик Нагрузки
resource "vkcs_lb_loadbalancer" "lb" {
  name          = "${var.project_name}-loadbalancer"
  description   = "Loadbalancer for web servers"
  vip_subnet_id = vkcs_networking_subnet.public_subnet.id

  # ИСПРАВЛЕНО: Убран устаревший аргумент security_group_ids
  # ИСПРАВЛЕНО: Зависимости depends_on Terraform строит сам, они здесь лишние
}

# 2. Слушатель (Слушает входящий порт 80)
resource "vkcs_lb_listener" "lb_http" {
  name            = "${var.project_name}-listener-http"
  loadbalancer_id = vkcs_lb_loadbalancer.lb.id
  protocol        = "HTTP"
  protocol_port   = 80
}

# 3. Пул серверов
resource "vkcs_lb_pool" "http" {
  name        = "${var.project_name}-pool-http"
  listener_id = vkcs_lb_listener.lb_http.id
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN" # Алгоритм распределения трафика по очереди
}

# 4. Проверка работоспособности (Health Check)
resource "vkcs_lb_monitor" "worker_ping_life_checker" {
  name        = "${var.project_name}-health-monitor"
  pool_id     = vkcs_lb_pool.http.id
  type        = "HTTP"
  delay       = 10
  timeout     = 5
  max_retries = 3
  url_path    = "/"
}

# 5. Привязка веб-серверов к Балансировщику
resource "vkcs_lb_member" "web_servers_members" {
  # Перебираем наши веб-серверы
  for_each      = vkcs_compute_instance.web_server 
  pool_id       = vkcs_lb_pool.http.id
  protocol_port = 80                               
  subnet_id     = vkcs_networking_subnet.private_subnet.id

  # ИСПРАВЛЕНО: Надежный способ забрать IP-адрес через готовые порты
  address       = vkcs_networking_port.web_server_port[each.key].all_fixed_ips[0]
}






esource "local_file" "k8s_configmap" {
  # Указываем путь к шаблону на уровень выше (в корень проекта)
  content = templatefile("${path.module}/../templates/configmap.yaml.tpl", {
    lb_ip = vkcs_lb_loadbalancer.lb.vip_address
  })
  
  # Сохраняем сгенерированный файл в папку kubernetes на уровень выше
  filename = "${path.module}/../kubernetes/configmap.yaml"
}
