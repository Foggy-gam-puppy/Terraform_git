# 1. Балансировщик нагрузки
resource "vkcs_lb_loadbalancer" "lb" {
  name          = "${var.project_name}-loadbalancer"
  description   = "Loadbalancer for web servers"
  vip_subnet_id = vkcs_networking_subnet.public_subnet.id

}

# 2. Слушатель 
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
  lb_method   = "ROUND_ROBIN" 
}

# 4. Проверка работоспособности
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
  for_each      = vkcs_compute_instance.web_server 
  pool_id       = vkcs_lb_pool.http.id
  protocol_port = 80                               
  subnet_id     = vkcs_networking_subnet.private_subnet.id

  address       = vkcs_networking_port.web_server_port[each.key].all_fixed_ips[0]
}


resource "local_file" "k8s_configmap" {
  
  content = templatefile("${path.module}/../templates/configmap.yaml.tpl", {
    lb_ip = vkcs_lb_loadbalancer.lb.vip_address
  })
  
  filename = "${path.module}/../kubernetes/configmap.yaml"
}
