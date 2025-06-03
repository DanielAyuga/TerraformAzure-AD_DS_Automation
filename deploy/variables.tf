variable "subscription_id" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true  # Oculta la contraseña en logs
}

variable "ruta_local_ad_setup" {
  type      = string
  sensitive = true  # Oculta la ruta en logs
}

variable "ruta_local_post_ad_setup" {
  type      = string
  sensitive = true  # Oculta la ruta en logs
}
