# TerraformAzure-AD_DS_Automation
## Creación automatizada de una máquina virtual "Windows Server 2019" con "Active Directory Domain Services" + configuración automatizada

No solo crearé de forma automática este AD-DS, sino que tras la creación de la máquina virtual, se iniciará y ejecutará un script de PowerShell que configurará nuestro Active Directory.
<br><br>
Para ello, desde Terraform, también crearé:

  - Un grupo de recursos
  
  - Una vnet y una subnet
  
  - Una subnet para Azure Bastión
  
  - Un grupo de seguridad de red (NSG) + reglas
  
  - Una interfaz de red (NIC)
  
  - Una maquina virtual + extensión customscript
  
  - El host Bastión
  
  - La IP pública de Bastión
  
  - Una Storage Account
  
  - Un contenedor de blobs
  
  - Un blob
<br><br>
*La carpeta deploy contiene todos los archivos de configuración y la carpeta docs contiene estos documentos explicados, así como un esquema visual y recomendaciones particulares y generales para desarrollar este y otros proyectos*
