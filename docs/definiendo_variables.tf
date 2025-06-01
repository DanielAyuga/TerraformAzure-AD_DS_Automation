## Definiendo variables.tf

En este ejemplo nuestras variables, solo hacen referencia al nombre que tendrán entre "" y el tipo, que en este caso son string (cadena)
Se asocia esta variable al valor que tienen en secrets.tfvars (sin tener que usar texto plano) y este nombre lo usaremos en el archivo main.tf de configuración.

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
