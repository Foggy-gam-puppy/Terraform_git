terraform {
  required_version = "~> 1.0"
  
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.1"
    }
  }

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

}

