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
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-ad-ds"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}

resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  # Bastion requiere IP Standard
}

# Cuenta de almacenamiento
resource "azurerm_storage_account" "storage" {
  name                     = "mystaccdsfs64565dfsrhs"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Contenedor para la cuenta de almacenamiento
resource "azurerm_storage_container" "scripts_container" {
  name                  = "scripts"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "blob"
}

# Blob
resource "azurerm_storage_blob" "ad_setup_script" {
  name                   = "ad_setup.ps1"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.scripts_container.name
  type                   = "Block"
  source                 = var.ruta_local
}

# Extensión de vm
resource "azurerm_virtual_machine_extension" "run_ad_setup" {
  name                 = "run-ad-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.ad-ds-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "fileUris": ["https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri 'https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1' -OutFile 'C:\\ad_setup.ps1'; powershell -ExecutionPolicy Unrestricted -File C:\\ad_setup.ps1\""
    }
SETTINGS
}
