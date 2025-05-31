# TerraformAzure-AD_DS_Automation
## Creación automatizada de una máquina virtual "Windows Server 2019" con "Active Directory Domain Services"

No solo crearé de forma automática este AD-DS, sino que tras la creación de la máquina virtual, se iniciará y ejecutará un script de PowerShell que configurará nuestro Active Directory.

Para la creación mencionada, desde Terraform, también crearé:
  -Un grupo de recursos
  -Una vnet y una subnet
  -Una subnet para Azure Bastión
  -Un grupo de seguridad de red (NSG)
  -Una interfaz de red (NIC)
  -Una maquina virtual
  -El propio Bastión
  -La IP pública de Bastión
  -Una Storage Account
  -Un contenedor de blobs

  
