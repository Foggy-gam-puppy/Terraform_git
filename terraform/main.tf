terraform {
  required_version = "~> 1.0"
  
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.1"
    }
  }

  # 줍脚羔 켑慨터 줆農 喫近촘 픔턺 INSIDE TERRAFORM!
  backend "s3" {
    bucket                      = "terraform-state-foggy-lab2"
    key                         = "lab2/terraform.tfstate"
    region                      = "ru-msk"
    endpoint                    = "https://hb.ru-msk.vkcloud-storage.ru"  
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

provider "vkcs" {
  # 잡桎鳥裔打 了 vkrc
}

provider "kubernetes" {
  # Указываем путь к твоему файлу кубернетиса, который лежит в репозитории

}

# Используем новый тип данных _v1, чтобы убрать Warning
data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

resource "kubernetes_config_map" "lb_ip_config" {
  metadata {
    name      = "balancer-config"
    namespace = "my-app-prod"
  }

  data = {
    # Новый чистый синтаксис без лишних индексов
    balancer_ip = data.kubernetes_service_v1.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
  }
}
