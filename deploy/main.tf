# Grupo de recursos
resource "azurerm_resource_group" "rg" {
  provider = azurerm
  name     = "AD-DS-rg"
  location = "East US"

  tags = {
    environment = "test"
  }
}

# Red virtual y subred
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ad-ds"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-ad-ds"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Grupo de seguridad de red
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ad-ds"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Reglas de NSG
resource "azurerm_network_security_rule" "allow_bastion_rdp" {
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Allow-Bastion-RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefixes       = ["10.0.2.0/27"]
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Deny-All-Inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_storage_access" {
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Allow-Storage-Access"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Storage"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Deny-All-Outbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
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

# Subred para Azure Bastion
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"  # Nombre obligatorio
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/27"]  # Recomendado para Bastion
}

# IP pública para Azure Bastión
resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  # Bastion requiere IP Standard
}

# Interfaz de red
resource "azurerm_network_interface" "nic-ad-ds" {
  name                = "nic-ad-ds"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-ad-ds"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Máquina virtual con Windows Server 2019
resource "azurerm_windows_virtual_machine" "ad-ds-vm" {
  name                = "ad-ds-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2S_v3"
  admin_username      = "adminuser"
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic-ad-ds.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"  # Managed Identity activada
  }
}

# Creación de la extensión "CustomScriptExtension"
resource "azurerm_virtual_machine_extension" "run_ad_setup" {
  name                 = "run-ad-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.ad-ds-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri 'https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/ad_setup.ps1${data.azurerm_storage_account_sas.storagesas.sas}' -OutFile 'C:\\ad_setup.ps1'; Invoke-WebRequest -Uri 'https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts_container.name}/post_ad_setup.ps1${data.azurerm_storage_account_sas.storagesas.sas}' -OutFile 'C:\\post_ad_setup.ps1'; & 'C:\\ad_setup.ps1'\""
  })
}

# Cuenta de almacenamiento
resource "azurerm_storage_account" "storage" {
  name                     = "mystaccdsfs64565dfsrhs"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny" # Bloquea accesos desde Internet
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id] # Permite solo acceso desde la VNet
    bypass                     = ["AzureServices"] # Permite acceso desde servicios internos de Azure
  }
}

# Creación de contenedor
resource "azurerm_storage_container" "scripts_container" {
  name                  = "scripts"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Creación del blob dentro del contenedor
resource "azurerm_storage_blob" "ad_setup_script" {
  name                   = "ad_setup.ps1"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.scripts_container.name
  type                   = "Block"
  source                 = var.ruta_local_ad_setup
}

# Creación del blob dentro del contenedor
resource "azurerm_storage_blob" "post_ad_setup_script" {
  name                   = "post_ad_setup.ps1"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.scripts_container.name
  type                   = "Block"
  source                 = var.ruta_local_post_ad_setup
}

#Creación del key vault
resource "azurerm_key_vault" "keyvault" {
  name                = "mykvdsfs64565dfsrhs"  # Debe ser único globalmente
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  enable_rbac_authorization = true
}

# Asignación rol administrador key vault
resource "azurerm_role_assignment" "kv_secrets_admin" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Creación de SAS token
resource "azurerm_key_vault_secret" "sas_token" {
  name         = "blob-sas-token"
  value        = data.azurerm_storage_account_sas.storagesas.sas
  key_vault_id = azurerm_key_vault.keyvault.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin
  ]
}

# Asignación de Usuario de Secretos a la VM
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.ad-ds-vm.identity[0].principal_id
}
