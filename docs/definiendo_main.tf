## Definiendo main.tf

# Grupo de recursos
resource "azurerm_resource_group" "rg" {    #Indicamos con "azurerm_resource_group" que el recurso que vamos a crear es resource group al que llamaremos "rg" en terraform
  provider = azurerm                        #Indicamos qué "azurerm" es el provider que se encarga de la gestión de los recursos
  name     = "AD-DS-rg"                     #Nombre del recurso en Azure
  location = "East US"                      #Localización donde se va a crear

  tags = {                                  #Etiquetas que queramos añadir
    environment = "test"                    #En este caso: test
  }
}

# Red virtual y subred
resource "azurerm_virtual_network" "vnet" {                        #Indicamos con "azurerm_virtual_network" que el recurso que vamos a crear es una red virtual que llamaremos "vnet" en terraform
  name                = "vnet-ad-ds"                               #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location         #Se toma la ubicación del grupo de recursos definido anteriormente
  resource_group_name = azurerm_resource_group.rg.name             #En que grupo de recursos creamos la vnet. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  address_space       = ["10.0.0.0/16"]                            #Prefijo CIDR de la vnet /16 (10.0.0.1 - 10.0.255.254) (excluyendo la primera 10.0.0.0 y última 10.0.255.255 para red y broadcast)
}

resource "azurerm_subnet" "subnet" {                               #Indicamos con "azurerm_subnet" que el recurso que vamos a crear es una subnet que llamaremos "subnet" en terraform
  name                 = "subnet-ad-ds"                            #Nombre del recurso en Azure
  resource_group_name  = azurerm_resource_group.rg.name            #En que grupo de recursos creamos la subnet. En este caso en el rg hemos definido (rg.name)
  virtual_network_name = azurerm_virtual_network.vnet.name         #A que vnet asociaremos esta subnet. vnet.name (vnet.vnet-ad-ds)
  address_prefixes     = ["10.0.1.0/24"]                           #Prefijo CIDR de la subnet /24 (10.0.1.1 - 10.0.1.254) (excluyendo la primera 10.0.1.0 y última 10.0.1.255 para red y broadcast)


# Grupo de seguridad de red
resource "azurerm_network_security_group" "nsg" {                         #Indicamos con "azurerm_network_security_group" que el recurso que vamos a crear es un nsg que llamaremos "nsg" en terraform
  name                = "nsg-ad-ds"                                       #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #Se toma la ubicación del grupo de recursos definido anteriormente
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos el nsg. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
}

# Reglas de NSG
resource "azurerm_network_security_rule" "allow_bastion_rdp" {           #Indicamos con "azurerm_network_security_rule" que el recurso que vamos a crear es una regla para el nsg que llamaremos "allow_bastion_rdp" en terraform
  resource_group_name         = azurerm_resource_group.rg.name           #En que grupo de recursos creamos la regla. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  name                        = "Allow-Bastion-RDP"                      #Nombre de la regla en Azure
  priority                    = 100                                      #Prioridad de la regla. Cuanto mas bajo es el numero, mayor prioridad. Está regla será la primera en aplicar para tráfico entrante
  direction                   = "Inbound"                                #En que sentido se aplica la regla. En este caso tráfico entrante
  access                      = "Allow"                                  #Accion. Permitir/Denegar. En este caso permite
  protocol                    = "Tcp"                                    #Protocolo de comunicación
  source_port_range           = "*"                                      #Puerto origen del tráfico. * es cualquier puerto
  destination_port_range      = "3389"                                   #Puerto de destino del tráfico. 3389 RDP (Remote Desktop Protocol)
  source_address_prefix       = ["10.0.2.0/27"]                          #Origen de tráfico. AzureBastionSubnet
  destination_address_prefix  = "VirtualNetwork"                         #Destino del tráfico. Virtual Network
  network_security_group_name = azurerm_network_security_group.nsg.name  #Nombre del nsg. Hacemos referencia al recurso nsg creado.
}

resource "azurerm_network_security_rule" "deny_all_inbound" {            #Indicamos con "azurerm_network_security_rule" que el recurso que vamos a crear es una regla para el nsg que llamaremos "deny_all_inbound" en terraform
  resource_group_name         = azurerm_resource_group.rg.name           #En que grupo de recursos creamos la regla. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  name                        = "Deny-All-Inbound"                       #Nombre de la regla en Azure
  priority                    = 200                                      #Prioridad de la regla. Cuanto mas bajo es el numero, mayor prioridad. Está regla será la segunda en aplicar para tráfico entrante
  direction                   = "Inbound"                                #En que sentido se aplica la regla. En este caso tráfico entrante
  access                      = "Deny"                                   #Accion. Permitir/Denegar. En este caso deniega
  protocol                    = "*"                                      #Protocolo de comunicación. * es cualquier protocolo
  source_port_range           = "*"                                      #Puerto origen del tráfico. * es cualquier puerto
  destination_port_range      = "*"                                      #Puerto destino del tráfico. * es cualquier puerto
  source_address_prefix       = "Internet"                               #Origen de tráfico. Cualquier tráfico externo que no provenga de la red interna de Azure 
  destination_address_prefix  = "*"                                      #Destino del tráfico. Cualquiera (ya sea la vm, o cualquier otro servicio de Azure)
  network_security_group_name = azurerm_network_security_group.nsg.name  #Nombre del nsg. Hacemos referencia al recurso nsg creado.
}

resource "azurerm_network_security_rule" "allow_storage_access" {        #Indicamos con "azurerm_network_security_rule" que el recurso que vamos a crear es una regla para el nsg que llamaremos "allow_storage_access" en terraform
  resource_group_name         = azurerm_resource_group.rg.name           #En que grupo de recursos creamos la regla. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  name                        = "Allow-Storage-Access"                   #Nombre de la regla en Azure
  priority                    = 100                                      #Prioridad de la regla. Cuanto mas bajo es el numero, mayor prioridad. Está regla será la primera en aplicar para tráfico saliente
  direction                   = "Outbound"                               #En que sentido se aplica la regla. En este caso tráfico saliente
  access                      = "Allow"                                  #Accion. Permitir/Denegar. En este caso permite
  protocol                    = "Tcp"                                    #Protocolo de comunicación
  source_port_range           = "*"                                      #Puerto origen del tráfico. * es cualquier puerto
  destination_port_range      = "443"                                    #Puerto destino del tráfico. 443 HTTPS (Hypertext Transfer Protocol Secure)
  source_address_prefix       = "VirtualNetwork"                         #Origen del tráfico. Virtual Network
  destination_address_prefix  = "Storage"                                ##Destino del tráfico. Servicio Almacenamiento
  network_security_group_name = azurerm_network_security_group.nsg.name  #Nombre del nsg. Hacemos referencia al recurso nsg creado.
}

resource "azurerm_network_security_rule" "deny_all_outbound" {           #Indicamos con "azurerm_network_security_rule" que el recurso que vamos a crear es una regla para el nsg que llamaremos "deny_all_outbound" en terraform
  resource_group_name         = azurerm_resource_group.rg.name           #En que grupo de recursos creamos la regla. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  name                        = "Deny-All-Outbound"                      #Nombre de la regla en Azure
  priority                    = 200                                      #Prioridad de la regla. Cuanto mas bajo es el numero, mayor prioridad. Está regla será la segunda en aplicar para tráfico saliente
  direction                   = "Outbound"                               #En que sentido se aplica la regla. En este caso tráfico saliente
  access                      = "Deny"                                   #Accion. Permitir/Denegar. En este caso deniega
  protocol                    = "*"                                      #Protocolo de comunicación. * es cualquier protocolo
  source_port_range           = "*"                                      #Puerto origen del tráfico. * es cualquier puerto
  destination_port_range      = "*"                                      #Puerto destino del tráfico. * es cualquier puerto
  source_address_prefix       = "*"                                      #Origen del tráfico. * es cualquier origen
  destination_address_prefix  = "*"                                      #Destino del tráfico. * es cualquier destino
  network_security_group_name = azurerm_network_security_group.nsg.name  #Nombre del nsg. Hacemos referencia al recurso nsg creado.
}

# Azure Bastion
resource "azurerm_bastion_host" "bastion" {                               #Indicamos con "azurerm_bastion_host" que el recurso que vamos a crear es un Bastion que llamaremos "bastion" en terraform
  name                = "bastion-ad-ds"                                   #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #Se toma la ubicación del grupo de recursos definido anteriormente
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos el Bastion. En el que hemos creado rg.name (rg.AD-DS-rg)

  ip_configuration {                                                      #Definimos la configuración IP que tendrá
    name                 = "bastion-ip-config"                            #Nombre de la configuración de IP dentro del recurso Bastion
    subnet_id            = azurerm_subnet.bastion_subnet.id               #Asociamos Bastion a su subnet específica
    public_ip_address_id = azurerm_public_ip.bastion_ip.id                #Asociamos Bastion a la IP pública que crearemos a continuación
  }
}

# Subred para Azure Bastion    
resource "azurerm_subnet" "bastion_subnet" {                              #Indicamos con "azurerm_subnet" que el recurso que vamos a crear es una subnet que llamaremos "bastion_subnet" en terraform
  name                 = "AzureBastionSubnet"                             #Nombre **OBLIGATORIO** para la subnet de Bastion en Azure. Si no tiene este nombre rechaza la configuración
  resource_group_name  = azurerm_resource_group.rg.name                   #En que grupo de recursos creamos la subnet. En este caso en el rg hemos definido (rg.name)
  virtual_network_name = azurerm_virtual_network.vnet.name                #A que vnet asociaremos esta subnet. vnet.name (vnet.vnet-ad-ds)
  address_prefixes     = ["10.0.2.0/27"]                                  #Permitido /27-/24 (/27 recomendado para Bastion)
}

resource "azurerm_public_ip" "bastion_ip" {                               #Indicamos con "azurerm_public_ip" que el recurso que vamos a crear es una IP publica que llamaremos "bastion_ip" en terraform
  name                = "bastion-public-ip"                               #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #Se toma la ubicación del grupo de recursos definido anteriormente
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la IP publica. En el que hemos creado rg.name (rg.AD-DS-rg)
  allocation_method   = "Static"                                          #Bastion siempre requiere que la IP sea estática, no cambiará
  sku                 = "Standard"                                        #Bastion requiere una IP Standard porque ofrece mejor resiliencia, seguridad y compatibilidad con redes emparejadas
}

# Interfaz de red
resource "azurerm_network_interface" "nic-ad-ds" {                        #Indicamos con "azurerm_network_interface" que el recurso que vamos a crear es una NIC que llamaremos "nic-ad-ds" en terraform
  name                = "nic-ad-ds"                                       #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #Se toma la ubicación del grupo de recursos definido anteriormente
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la NIC. En el que hemos creado rg.name (rg.AD-DS-rg)

  ip_configuration {                                                      #Vamos a definir la configuración ip de la NIC
    name                          = "ipconfig-ad-ds"                      #Nombre de la configuración de IP dentro de la NIC
    subnet_id                     = azurerm_subnet.subnet.id              #En que subnet crearemos esta IP. Rango de direcciones disponibles: 10.0.1.1 - 10.0.1.254 (excluyendo la primera y última para red y broadcast)
    private_ip_address_allocation = "Dynamic"                             #De que forma se asignará la IP. Dynamic te la asigna automáticamente dentro del rango. Static puedes indicar tu la IP.
  }
}

# Máquina virtual con Windows Server 2019                                
resource "azurerm_windows_virtual_machine" "ad-ds-vm" {                   #Indicamos con "azurerm_windows_virtual_machine" que el recurso que vamos a crear es una maquina virtual que llamaremos "ad-ds-vm" en terraform
  name                = "ad-ds-vm"                                        #Nombre del recurso en Azure
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la vm. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  location            = azurerm_resource_group.rg.location                #Se toma la ubicación del grupo de recursos definido anteriormente
  size                = "Standard_D2S_v3"                                 #Tipo de vm (SKU). Familia Dsv3 (optimizada para computación general) | vCPUs: 2 | RAM: 8 GB | Disco temporal: 16 GB | Soporte para almacenamiento premium SSD: Sí.
  admin_username      = "adminuser"                                       #Nombre del usuario administrador de la vm
  admin_password      = var.admin_password                                #Password del usuario administrador de la vm. **La pasamos en secrets.tfvars como sensible**

  network_interface_ids = [azurerm_network_interface.nic-ad-ds.id]        #Asociamos la NIC que hemos credao a esta vm. Hacemos referencia a su .id. (Aunque de momento no tenga .id Terraform hace la asociacion en la creación)

  os_disk {                                                               #Disco del sistema operativo
    caching              = "ReadWrite"                                    #Politica de caché: Permite leer y escribir (podría ser "none" o "readonly"
    storage_account_type = "Standard_LRS"                                 #Tipo de almacenamiento para el disco: Standard_LRS almacena 3 copias del disco dentro de un mismo datacenter, el cual pertenece a una única zona de disponibilidad de la región
  }

  source_image_reference {                                                #Definiremos que imagen usaremos de vm
    publisher = "MicrosoftWindowsServer"                                  #Entidad que proporciona la imagen
    offer     = "WindowsServer"                                           #Oferta, corresponde a que familia pertenece la imagen
    sku       = "2019-Datacenter"                                         #SKU (Stock Keeping Unit) dentro de esta familia
    version   = "latest"                                                  #Última versión disponible de Windows Server 2019 Datacenter en el mercado de imágenes de Azure
  }

  identity {
    type = "SystemAssigned"                                               #Creamos una identidad administrada para la VM a la que podremos asignar permisos
  }
}

# Creación de la extensión "CustomScriptExtension"
resource "azurerm_virtual_machine_extension" "run_ad_setup" {                    #Indicamos con "azurerm_virtual_machine_extension" que el recurso que vamos a crear es una extensión de vm que llamaremos "run_ad_setup" en terraform
  name                 = "run-ad-setup"                                          #Nombre del recurso en Azure
  virtual_machine_id   = azurerm_windows_virtual_machine.ad-ds-vm.id             #Referenciamos que vm será la que ejecute este script
  publisher            = "Microsoft.Compute"                                     #Entdidad del script a ejecutar
  type                 = "CustomScriptExtension"                                 #Tipo de extensión. En este caso el de script personalizado
  type_handler_version = "1.10"                                                  #Versión específica de la extensión CustomScriptExtension que se ejecutará en la VM

  #El siguiente apartado *SETTINGS* define lo que hará la extensión custom script:
  #Indicamos que ejecute un comando Invoke-WebRequest, 2 veces, hace una petición web de cada script definiendo su ruta. Copiamos el script en la VM en C: y ejecuta solamente el primer script (ad_setup.ps1) desde PowerShell
  #La ruta de los scripts la formamos mediante variables de la configuración https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1${data.azurerm_storage_account_sas.storagesas.sas}'
  
  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri 'https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1${data.azurerm_storage_account_sas.storagesas.sas}' -OutFile 'C:\\ad_setup.ps1'; Invoke-WebRequest -Uri 'https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/post_ad_setup.ps1${data.azurerm_storage_account_sas.storagesas.sas}' -OutFile 'C:\\post_ad_setup.ps1'; & 'C:\\ad_setup.ps1'\""
  })
}

# Cuenta de almacenamiento
resource "azurerm_storage_account" "storage" {                            #Indicamos con "azurerm_storage_account" que el recurso que vamos a crear es una cuenta de almacenamiento que llamaremos "storage" en terraform
  name                     = "mystaccdsfs64565dfsrhs"                     #Nombre del recurso en Azure *DEBE SER UNICO GLOBALMENTE*
  resource_group_name      = azurerm_resource_group.rg.name               #En que grupo de recursos creamos la cuenta de almacenamiento. En el que hemos creado rg.name (rg.AD-DS-rg)
  location                 = azurerm_resource_group.rg.location           #Se toma la ubicación del grupo de recursos definido anteriormente
  account_tier             = "Standard"                                   #Rendimiento de la cuenta. Con Standard para el ejemplo es suficiente. (Puede ser premium)
  account_replication_type = "LRS"                                        #Tipo redundancia para la cuenta: Standard_LRS almacena 3 copias del disco dentro de un mismo datacenter, el cual pertenece a una única zona de disponibilidad de la región 
}

# Contenedor para la cuenta de almacenamiento
resource "azurerm_storage_container" "scripts_container" {               #Indicamos con "azurerm_storage_container" que el recurso que vamos a crear es un contenedor que llamaremos "scripts_container" en terraform
  name                  = "scripts"                                      #Nombre del recurso en Azure
  storage_account_id    = azurerm_storage_account.storage.id             #En que cuenta de almacenamiento creamos el contenedor. Terraform vinculará automáticamente el contenedor a la cuenta de almacenamiento en el momento de la creación
  container_access_type = "private"                                      #Tipo de acceso del contenedor. Privado (podría ser también blob o container)
}

# Creación del blob dentro del contenedor
resource "azurerm_storage_blob" "ad_setup_script" {                              #Indicamos con "azurerm_storage_blob" que el recurso que vamos a crear es un blob que llamaremos "ad_setup_script" en terraform
  name                   = "ad_setup.ps1"                                        #Nombre del blob en Azure
  storage_account_name   = azurerm_storage_account.storage.name                  #En que cuenta de almacenamiento creamos el blob
  storage_container_name = azurerm_storage_container.scripts_container.name      #En que contenedor creamos el blob
  type                   = "Block"                                               #Tipo de blob, bloque: facilita operaciones de carga, actualización y recuperación de manera eficiente
  source                 = var.ruta_local_ad_setup                               #Donde se encuentra el script que vamos a subir al contenedor. A la ruta hacemos referencia en variables.tf y secrets.tfvars ("C:/Microsoft VS Code/code/active_directoy/active_directory-vm/scripts/ad_setup.ps1")
}

# Creación del blob dentro del contenedor
resource "azurerm_storage_blob" "post_ad_setup_script" {                         #Indicamos con "azurerm_storage_blob" que el recurso que vamos a crear es un blob que llamaremos "post_ad_setup_script" en terraform
  name                   = "post_ad_setup.ps1"                                   #Nombre del blob en Azure
  storage_account_name   = azurerm_storage_account.storage.name                  #En que cuenta de almacenamiento creamos el blob
  storage_container_name = azurerm_storage_container.scripts_container.name      #En que contenedor creamos el blob
  type                   = "Block"                                               #Tipo de blob, bloque: facilita operaciones de carga, actualización y recuperación de manera eficiente
  source                 = var.ruta_local_post_ad_setup                          # #Donde se encuentra el script que vamos a subir al contenedor. A la ruta hacemos referencia en variables.tf y secrets.tfvars ("C:/Microsoft VS Code/code/active_directoy/active_directory-vm/scripts/post_ad_setup.ps1")
}

#Creación del key vault
resource "azurerm_key_vault" "keyvault" {                                 #Indicamos con "azurerm_key_vault" que el recurso que vamos a crear es un Key Vault que llamaremos "keyvault" en terraform
  name                = "mykvdsfs64565dfsrhs"                             #Nombre del recurso en Azure. Debe ser **ÚNICO GLOBALMENTE**
  location            = azurerm_resource_group.rg.location                #Se toma la ubicación del grupo de recursos definido anteriormente
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la cuenta de almacenamiento. En el que hemos creado rg.name (rg.AD-DS-rg)
  tenant_id           = var.tenant_id                                     #Definimos que será la variable "var.tenant_id". Coge el valor de secrets.tfvars
  sku_name            = "standard"                                        #Tipo de Key Vault de uso mas genérico
  enable_rbac_authorization = true                                        #Habilita el uso de Azure Role-Based Access Control (RBAC) para gestionar el acceso
}

# Asignación rol administrador key vault
resource "azurerm_role_assignment" "kv_secrets_admin" {                   #Indicamos con "azurerm_role_assignment" que asignaremos un rol que llamaremos "kv_secrets_admin" en terraform
  scope                = azurerm_key_vault.keyvault.id                    #Aplicaremos este rol sobre el kayvault haciendo referencia a su id
  role_definition_name = "Key Vault Administrator"                        #Nombre del rol en Azure. Tambien podemos hacer referencia al id del rol.
  principal_id         = data.azurerm_client_config.current.object_id     #A quién asignamos el rol. Esto hace referencia al cliente o entidad que ejcuta esta configuración de Terraform. Se define en data.tf
}

# Creación de SAS token
resource "azurerm_key_vault_secret" "sas_token" {                         #Indicamos con "azurerm_key_vault_secret" que el recurso que vamos a crear es un secreto Key Vault que llamaremos "sas_token" en terraform
  name         = "blob-sas-token"                                         #Nombre del recurso en Azure
  value        = data.azurerm_storage_account_sas.storagesas.sas          #El valor (la confgiuración) del SAS token lo referenciamos de data.tf
  key_vault_id = azurerm_key_vault.keyvault.id                            #Crearemos este secreto sobre el kayvault haciendo referencia a su id

  depends_on = [                                                          #Hacemos referencia a que este recurso depende de la asincación del rol de Administrador de Key Vault
    azurerm_role_assignment.kv_secrets_admin                              #Nos aseguramos que primero se asigne el rol y luego se cree el secreto. Evitamos el error
  ]
}

# Asignación de Usuario de Secretos a la VM
resource "azurerm_role_assignment" "kv_secrets_user" {                                        #Indicamos con "azurerm_role_assignment" que asignaremos un rol que llamaremos "kv_secrets_user" en terraform
  scope                = azurerm_key_vault.keyvault.id                                        #Aplicaremos este rol sobre el kayvault haciendo referencia a su id
  role_definition_name = "Key Vault Secrets User"                                             #Nombre del rol en Azure. Tambien podemos hacer referencia al id del rol.
  principal_id         = azurerm_windows_virtual_machine.ad-ds-vm.identity[0].principal_id    #A quién asignamos el rol. Esto hace referencia a la identidad administrada de la VM
}
