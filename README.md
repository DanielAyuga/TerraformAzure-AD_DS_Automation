# TerraformAzure-AD_DS_Automation
## Creación automatizada de una máquina virtual "Windows Server 2019" con "Active Directory Domain Services" (configuración automatizada)

No solo crearé de forma automática esta máquina virtual, sino que tras la creación de la máquina virtual, se iniciará y ejecutará un script de PowerShell que configurará nuestro Active Directory, DNS y bosque. Una vez que hagamos el login, mediante una tarea programada en PoweShell, ejecutará un segundo script que acabará de configurar la máquina (unidad organizativa, GPOs y alta de usuarios automatizada en el dominio). Esto mediante un token SAS, almacenado en Key Vault, que permitirá a la identidad administrada de la máquina virtual acceder al contenedor de la cuenta de almacenamiento y descargar los scripts necesarios para la configuración.
<br><br>
Esta arquitectura de Azure, no solo pretende desplegar los recursos, sino hacerla en si misma coherente y segura dotando al administrador del tenant la capacidad de 
interactuar con la máquina virtual de forma segura a través de Azure Bastion.
<br><br>
Para ello, desde Terraform, crearé:

  - Un grupo de recursos
  
  - Una vnet y una subnet
  
  - Un grupo de seguridad de red (NSG) + reglas

  - El host Bastión

  - Una subnet para Azure Bastión

  - La IP pública de Bastión

  - Una maquina virtual + extensión customscript
  
  - Una interfaz de red (NIC) para la máquina virtual

  -Un Azure Key Vault

  -Un SAS (Shared Access Signature) token
  
  - Una Storage Account
  
  - Un contenedor de blobs
  
  - Dos blobs

  - Asignación de roles necesarios
<br><br>
*La carpeta deploy contiene todos los archivos de configuración y la carpeta docs contiene estos documentos explicados, así como un esquema visual y recomendaciones particulares y generales para desarrollar este y otros proyectos*
