
variable "availability_zone" {
  type        = string
  default     = "MS1"
  description = "availability_zone for recource"
}

variable "project_name" {
  type    = string
  default = "lab2_project"
}

variable "my_ip" {
  description = "public IP for SSH access"
  type        = string
  sensitive   = true
}
variable "key_pair"{
   type      = string
}


variable "flavor"{

 type        = string
 default     = "Basic-1-1-10" 
 description = "Flavor for web servers and bastion"
}

variable "db_flavor"{

 type        = string
 default     = "STD2-2-8" 
 description = "Flavor for database"

}

variable "lab2_public"{
 
 description = "public subnet"
 type        = string
 default     = "10.0.1.0/24"

}

variable "lab2_private"{
 
 description = "public subnet"
 type        = string
 default     = "10.0.2.0/24"

}

variable "image_name" {
  type        = string
  default     = "lab2-custom-image-2026-06-11-0631"
  description = "The image name created in Packer"
}


variable "db_password" {
  type        = string
  sensitive   = true
  description = "secret password"
}
