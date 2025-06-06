variable "tenant_id" {
  type = string
  sensitive = true
}

variable "subscription_id" {
  type = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "ruta_local_ad_setup" {
  type      = string
}

variable "ruta_local_post_ad_setup" {
  type      = string
}
