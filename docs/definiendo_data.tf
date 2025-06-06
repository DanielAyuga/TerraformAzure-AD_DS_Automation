## Definiendo data.tf

data "azurerm_client_config" "current" {}           #Obtemos la información del cliente que está interactuando con Azure. El que está aplicando esta configuración en Terraform

# Data del SAS token
data "azurerm_storage_account_sas" "storagesas" {   #Datos del token SAS que creamos en main.tf para la cuenta de almacenamiento
  connection_string = azurerm_storage_account.storage.primary_connection_string  #Utilizamos la cadena de conexión primaria de una cuenta de almacenamiento previamente definida
  https_only        = true                          #Permitimos que solo se puede utilizar mediante https
  start             = "2025-06-04T05:00:00Z"        #Fecha y hora de inicio del token_sas
  expiry            = "2025-06-08T00:00:00Z"        #Fecha y hora de expiración del token_sas

  resource_types {                                  #A que tipo de recursos permitimos (true) o no (false)
    service   = true                                #Permtimos servicio
    container = true                                #Permtimos contenedor
    object    = true                                #Permtimos objeto
  }

  services {                                        #Dentro de los servicios:
    blob = true                                     #Permtimos blob
    file = false                                    #Denegamos archivo
    table= false                                    #Denegamos tabla
    queue= false                                    #Denegamos cola
  }

    permissions {                                   #Que podremos hacer sobre el blob:
    read    = true                                  #Permtimos leer (y descargar)
    add     = false                                 #Denegamos el resto ya que no será necesario
    create  = false
    write   = false
    delete  = false
    list    = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
    
}
