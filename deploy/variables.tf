variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true  # Oculta la contraseña en logs
}

variable "ruta_local" {
  type      = string
  sensitive = true  # Oculta la ruta en logs
}
