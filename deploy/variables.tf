variable "tenant_id" {
  type = string
  sensitive = true  # Oculta la id en logs
}

variable "subscription_id" {
  type = string
  sensitive = true  # Oculta la id en logs
}

variable "admin_password" {
  type      = string
  sensitive = true  # Oculta la contraseña en logs
}

variable "blob_sas_token" {
  type      = string
  sensitive = true  # Oculta la contraseña en logs
}

variable "ruta_local_ad_setup" {
  type      = string
  sensitive = true  # Oculta la contraseña en logs
}

variable "ruta_local_post_ad_setup" {
  type      = string
  sensitive = true  # Oculta la contraseña en logs
}
