
packer{
  required_plugins {
    openstack = {
      version = "~>1.0"
      source = "github.com/hashicorp/openstack"
    }
  }
}

# Имя образа

variable "image_name" {
    type = string
        default     = "web-server-base"
        description = "Name of new flavor"
}

# Тип ВМ (flavor)
variable "flavor" {
    type = string
    default = "Basic-1-1-10"
    description = "flavor for VM"
}

# Базовой образ
variable "source_image" {
    type = string
    default = "242f95f8-12cb-4a17-af7d-a7da9bfc94c3"
    description = "ID image 'Ubunty 22.04'"
}

# ID сети
variable "network_id" {
    type = string
        default = "ec8c610e-6387-447e-83d2-d2c541e88164"
        description = "ID network 'internet'"
}

# Создание образа

source "openstack" "web-server-base" {
        flavor = "${var.flavor}"
        image_name = "${var.image_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
        source_image = "${var.source_image}" # 1 vCPU, 1 GB RAM, 10 GB
        config_drive = "true"
        networks = ["${var.network_id}"]
        ssh_username = "ubuntu"
        #volume_availability_zone = "MS1"
        security_groups          = ["security-group_for_practice"]
}
# Настройка ВМ

build{
sources = ["source.openstack.web-server-base"]
provisioner "shell" {
    inline = [
      "echo 'Updating system...'",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",

      "echo 'Installing nginx...'",
      "sudo apt-get install -y nginx",

      "echo 'Installing PHP...'",
     # "sudo apt-get install -y php-fpm php-pgsql",
      "sudo apt-get install -y --no-install-recommends php-fpm php-pgsql",
      "echo 'Configuring nginx...'",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",

      "echo 'Creating test page...'",
      "echo '<h1>Hello from Packer!</h1>' | sudo tee /var/www/html/index.html",

      "echo 'Cleaning up...'",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -f /var/lib/apt/lists/*"
    ]
  }
}

