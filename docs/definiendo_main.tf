## Definiendo main.tf

# Grupo de recursos
resource "azurerm_resource_group" "rg" {    #Indicamos con "azurerm_resource_group" que el recurso que vamos a crear es resource group al que llamaremos "rg" en terraform
  provider = azurerm                        #Indicamos qué "azurerm" es el provider que va a realizar la acción de dar de alta el recurso
  name     = "AD-DS-rg"                     #Nombre del recurso en Azure
  location = "East US"                      #Localización donde se va a crear

  tags = {                                  #Etiquetas que queramos añadir
    environment = "test"                    #En este caso: test
  }
}

# Red virtual y subred
resource "azurerm_virtual_network" "vnet" {                        #Indicamos con "azurerm_virtual_network" que el recurso que vamos a crear es una red virtual que llamaremos "vnet" en terraform
  name                = "vnet-ad-ds"                               #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location         #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  resource_group_name = azurerm_resource_group.rg.name             #En que grupo de recursos creamos la vnet. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  address_space       = ["10.0.0.0/16"]                            #Prefijo CIDR de la vnet /16 (10.0.0.1 - 10.0.255.254)
}

resource "azurerm_subnet" "subnet" {                               #Indicamos con "azurerm_subnet" que el recurso que vamos a crear es una subnet que llamaremos "subnet" en terraform
  name                 = "subnet-ad-ds"                            #Nombre del recurso en Azure
  resource_group_name  = azurerm_resource_group.rg.name            #En que grupo de recursos creamos la subnet. En este caso en el rg hemos definido (rg.name)
  virtual_network_name = azurerm_virtual_network.vnet.name         #A que vnet asociaremos esta subnet. vnet.name (vnet.vnet-ad-ds)
  address_prefixes     = ["10.0.1.0/24"]                           #Prefijo CIDR de la subnet /24 (10.0.1.1 - 10.0.1.254)
}

# Subred para Azure Bastion    
resource "azurerm_subnet" "bastion_subnet" {                              #Indicamos con "azurerm_subnet" que el recurso que vamos a crear es una subnet que llamaremos "bastion_subnet" en terraform
  name                 = "AzureBastionSubnet"  # Nombre obligatorio       #Nombre **OBLIGATORIO** para la subnet de Bastion en Azure. Si no tiene este nombre no funcionará.
  resource_group_name  = azurerm_resource_group.rg.name                   #En que grupo de recursos creamos la subnet. En este caso en el rg hemos definido (rg.name)
  virtual_network_name = azurerm_virtual_network.vnet.name                #A que vnet asociaremos esta subnet. vnet.name (vnet.vnet-ad-ds)
  address_prefixes     = ["10.0.2.0/27"]                                  #Permitido /27-/24 (/27 recomendado para Bastion)
}

# Grupo de seguridad de red
resource "azurerm_network_security_group" "nsg" {                         #Indicamos con "azurerm_network_security_group" que el recurso que vamos a crear es un nsg que llamaremos "nsg" en terraform
  name                = "nsg-ad-ds"                                       #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos el nsg. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
}

# Interfaz de red
resource "azurerm_network_interface" "nic-ad-ds" {                        #Indicamos con "azurerm_network_interface" que el recurso que vamos a crear es una NIC que llamaremos "nic-ad-ds" en terraform
  name                = "nic-ad-ds"                                       #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la NIC. En el que hemos creado rg.name (rg.AD-DS-rg)

  ip_configuration {                                                      #Vamos a definir la configuración ip de la NIC
    name                          = "ipconfig-ad-ds"                      #Nombre de la IP privada en Azure
    subnet_id                     = azurerm_subnet.subnet.id              #En que subnet crearemos esta IP. Estará dentro del rango 10.0.1.1 - 10.0.1.254 ["10.0.1.0/24"]
    private_ip_address_allocation = "Dynamic"                             #De que forma se asignará la IP. Dynamic te la asigna automáticamente dentro del rango. Static puedes indicar tu la IP.
  }
}
              
# Máquina virtual con Windows Server 2019                                
resource "azurerm_windows_virtual_machine" "ad-ds-vm" {                   #Indicamos con "azurerm_windows_virtual_machine" que el recurso que vamos a crear es una maquina virtual que llamaremos "ad-ds-vm" en terraform
  name                = "ad-ds-vm"                                        #Nombre del recurso en Azure
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la vm. En este caso en el rg que acabamos de definir rg.name (rg.AD-DS-rg)
  location            = azurerm_resource_group.rg.location                #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  size                = "Standard_D2S_v3"                                 #Tipo de vm (SKU). Familia Dsv3 (optimizada para computación general) | vCPUs: 2 | RAM: 8 GB | Disco temporal: 16 GB | Soporte para almacenamiento premium SSD: Sí.
  admin_username      = "adminuser"                                       #Nombre del usuario administrador de la vm
  admin_password      = var.admin_password                                #Password del usuario administrador de la vm. **La pasamos en secrets.tfvars como sensible**

  network_interface_ids = [azurerm_network_interface.nic-ad-ds.id]        #Asociamos la NIC que hemos credao a esta vm. Hacemos referencia a su .id. (Aunque de momento no tenga .id Terraform hace la asociacion en la creación)

  os_disk {                                                               #Disco del sistema operativo
    caching              = "ReadWrite"                                    #Politica de caché: Permite leer y escribir (podría ser "none" o "readonly"
    storage_account_type = "Standard_LRS"                                 #Tipo de almacenamiento para el disco: Standard_LRS = 3 copias del disco en el mismo centro de datos en una zona de disponibilidad (la región cuenta con 3 zonas de disponibilidad)
  }

  source_image_reference {                                                #Definiremos que imagen usaremos de vm
    publisher = "MicrosoftWindowsServer"                                  #Entidad que proporciona la imagen
    offer     = "WindowsServer"                                           #Oferta, corresponde a que familia pertenece la imagen
    sku       = "2019-Datacenter"                                         #SKU (Stock Keeping Unit) dentro de esta familia
    version   = "latest"                                                  #Ultima versión de los Windos Server 2019 Datacenter
  }
}

# Azure Bastion
resource "azurerm_bastion_host" "bastion" {                               #Indicamos con "azurerm_bastion_host" que el recurso que vamos a crear es un Bastion que llamaremos "bastion" en terraform
  name                = "bastion-ad-ds"                                   #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos el Bastion. En el que hemos creado rg.name (rg.AD-DS-rg)

  ip_configuration {                                                      #Definimos la configuración IP que tendrá
    name                 = "bastion-ip-config"                            #Nombre de la configuración IP en Azure
    subnet_id            = azurerm_subnet.bastion_subnet.id               #Asociamos Bastion a su subnet específica
    public_ip_address_id = azurerm_public_ip.bastion_ip.id                #Asociamos Bastion a la IP pública que crearemos a continuación
  }
}

resource "azurerm_public_ip" "bastion_ip" {                               #Indicamos con "azurerm_public_ip" que el recurso que vamos a crear es una IP publica que llamaremos "bastion_ip" en terraform
  name                = "bastion-public-ip"                               #Nombre del recurso en Azure
  location            = azurerm_resource_group.rg.location                #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  resource_group_name = azurerm_resource_group.rg.name                    #En que grupo de recursos creamos la IP publica. En el que hemos creado rg.name (rg.AD-DS-rg)
  allocation_method   = "Static"                                          #Bastion siempre requiere que la IP sea estática, no cambiará
  sku                 = "Standard"                                        #Bastion requiere IP Standard (entre otras cosas para poder acceder a vms en redes emparejadas)
}

# Cuenta de almacenamiento
resource "azurerm_storage_account" "storage" {                            #Indicamos con "azurerm_storage_account" que el recurso que vamos a crear es una cuenta de almacenamiento que llamaremos "storage" en terraform
  name                     = "mystaccdsfs64565dfsrhs"                     #Nombre del recurso en Azure *DEBE SER UNICO GLOBALMENTE*
  resource_group_name      = azurerm_resource_group.rg.name               #En que grupo de recursos creamos la cuenta de almacenamiento. En el que hemos creado rg.name (rg.AD-DS-rg)

  location                 = azurerm_resource_group.rg.location           #La localización será la que tenga el grupo de recursos (rg.location) rg -> nombre del grupo en terraform
  account_tier             = "Standard"                                   #Rendimiento de la cuenta. Con Standard para el ejemplo es suficiente. (Puede ser premium)
  account_replication_type = "LRS"                                        #Tipo redundancia para la cuenta: Standard_LRS = 3 copias de la cuenta en el mismo centro de datos en una zona de disponibilidad (la región cuenta con 3 zonas de disponibilidad) 
}

# Contenedor para la cuenta de almacenamiento
resource "azurerm_storage_container" "scripts_container" {               #Indicamos con "azurerm_storage_container" que el recurso que vamos a crear es un contenedor que llamaremos "scripts_container" en terraform
  name                  = "scripts"                                      #Nombre del recurso en Azure
  storage_account_id    = azurerm_storage_account.storage.id             #En que cuenta de almacenamiento creamos el contenedor. Hacemos referencia a su .id. (Aunque de momento no tenga .id Terraform hace la asociacion en la creación)

# Blob
resource "azurerm_storage_blob" "ad_setup_script" {                              #Indicamos con "azurerm_storage_blob" que el recurso que vamos a crear es un blob que llamaremos "ad_setup_script" en terraform
  name                   = "ad_setup.ps1"                                        #Nombre del blob en Azure
  storage_account_name   = azurerm_storage_account.storage.name                  #En que cuenta de almacenamiento creamos el blob
  storage_container_name = azurerm_storage_container.scripts_container.name      #En que contenedor creamos el blob
  type                   = "Block"                                               #Tipo de blob, bloque:
  source                 = var.ruta_local                                        #Donde se encuentra el script que vamos a subir al contenedor. A la ruta hacemos referencia en variables.tf y secrets.tfvars ("C:/Microsoft VS Code/code/active_directoy/active_directory-vm/scripts/ad_setup.ps1"=
}

# Extensión de vm
resource "azurerm_virtual_machine_extension" "run_ad_setup" {                    #Indicamos con "azurerm_virtual_machine_extension" que el recurso que vamos a crear es una extensión de vm que llamaremos "run_ad_setup" en terraform
  name                 = "run-ad-setup"                                          #Nombre del recurso en Azure
  virtual_machine_id   = azurerm_windows_virtual_machine.ad-ds-vm.id             #Referenciamos que vm será la que ejecute este script
  publisher            = "Microsoft.Compute"                                     #Entdidad del script a ejecutar
  type                 = "CustomScriptExtension"                                 #Tipo de extensión. En este caso el de script personalizado
  type_handler_version = "1.10"                                                  #Versión de la extensión

#En el apartado SETTINGS lo que vamos a definir es de donde va a coger la vm el script (primera linea "fileUris" en la que indicamos que será la cuenta de almacenamiento/contenedor/script)
#Que comando debe ejecutar. Indicamos que con Powershell ejecute lo que se indica (segunda linea)

  settings = <<SETTINGS                                                         
    {
      "fileUris": ["https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri 'https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1' -OutFile 'C:\\ad_setup.ps1'; powershell -ExecutionPolicy Unrestricted -File C:\\ad_setup.ps1\""
    }
SETTINGS
}
