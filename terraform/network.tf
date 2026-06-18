
data "vkcs_networking_network" "extnet" {
  name = "internet"
}

resource "vkcs_networking_router" "router" {
    name = "${var.project_name}-router"
    external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_network" "main" {
  name           = "${var.project_name}-network"
  admin_state_up = true
}

resource "vkcs_networking_subnet" "public_subnet" {
  name  = "${var.project_name}-public"
  network_id = vkcs_networking_network.main.id
  cidr       = var.lab2_public

  depends_on = [vkcs_networking_network.main]
 
}

resource "vkcs_networking_subnet" "private_subnet" {
  name  = "${var.project_name}-pr"
  network_id = vkcs_networking_network.main.id
  cidr       = var.lab2_private

   depends_on = [vkcs_networking_network.main]
  
}

resource "vkcs_networking_router_interface" "public_interface"{

  router_id = vkcs_networking_router.router.id
  subnet_id = vkcs_networking_subnet.public_subnet.id

}

resource "vkcs_networking_router_interface" "private_interface"{

  router_id = vkcs_networking_router.router.id
  subnet_id = vkcs_networking_subnet.private_subnet.id

}

resource "vkcs_networking_port" "bastion_port" {

    name = "bastion_port"
    network_id = vkcs_networking_network.main.id
    fixed_ip {
        subnet_id = vkcs_networking_subnet.public_subnet.id
  }
    full_security_groups_control = true
    security_group_ids = [vkcs_networking_secgroup.bastion_sg.id]


}

resource "vkcs_networking_floatingip" "fip_bastion" {
  pool = "internet"
}

resource "vkcs_networking_floatingip_associate" "fip_bastion_assoc" {
  floating_ip = vkcs_networking_floatingip.fip_bastion.address
  port_id     = vkcs_networking_port.bastion_port.id # —сылка на ваш порт

   depends_on = [
    vkcs_networking_router.router,
    vkcs_networking_router_interface.public_interface
  ]
}

resource "vkcs_networking_port" "web_server_port" {
  for_each           = toset(["1", "2"])
  name               = "web-server-port-${each.key}"
  network_id         = vkcs_networking_network.main.id
  security_group_ids = [vkcs_networking_secgroup.web_sg.id]
  
  fixed_ip {
    subnet_id = vkcs_networking_subnet.private_subnet.id
  }
}

resource "vkcs_networking_floatingip" "fip_lb" {
  pool = "internet"
}

resource "vkcs_networking_floatingip_associate" "fip_lb_assoc" {
  floating_ip = vkcs_networking_floatingip.fip_lb.address
  
  port_id     = vkcs_lb_loadbalancer.lb.vip_port_id 

  depends_on = [
    vkcs_networking_router.router,
    vkcs_networking_router_interface.public_interface,
    vkcs_lb_loadbalancer.lb # —ам балансировщик тоже должен создатьс€ до прив€зки IP
  ]
}












