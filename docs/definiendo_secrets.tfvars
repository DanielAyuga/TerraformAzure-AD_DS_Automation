## Definiendo secrets.tfvars

[¡IMPORTANTE!]
    -NO poner nunca contraseñas como texto plano en la configuración
    -Usaremos secrets.tfvars para pasar estas credenciales

En secrets.tfvars establecemos todos los valores *sensibles* y que no se incluiran dentro de la configuración
En el archivo .gitignore indicaremos que este archivo no se suba a git y por lo tanto no se incluya la información en el control de versiones

subscription_id               = "XXXXXXXX-XXXX-XXXX-XXXXXXXX"

admin_password                = "xxxxxxxxxxxx"

ruta_local_ad_setup           = "C:/Microsoft VS Code/code/active_directoy/active_directory-vm/scripts/ad_setup.ps1"           #Ruta del archivo que configura AD-DS, DNS y bosque
ruta_local_post_ad_setup      = "C:/Microsoft VS Code/code/active_directoy/active_directory-vm/scripts/post_ad_setup.ps1"      #Ruta del archivo que crea OU y GPO tras el reinicio de la instalación
