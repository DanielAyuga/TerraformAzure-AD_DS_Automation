## Definiendo ad_setup.ps1

#Configuración BASICA de AD-DS

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools   #Instala Active Directory Domain Services (ADDS) para permitir la creación de un dominio incluidas herramientas de administración como ADUC (Active Directory Users and Computers)
Install-WindowsFeature RSAT-AD-PowerShell                                 #Instala las herramientas de administración remota (RSAT) para Active Directory en PowerShell. Esto permite ejecutar comandos de AD directamente en PowerShell.
Import-Module ActiveDirectory                                             #Carga el módulo de Active Directory en PowerShell, habilitando el uso de cmdlets como Install-ADDSForest o New-GPO
Install-WindowsFeature -Name DNS -IncludeManagementTools                  #Instala el servicio DNS, para resolver nombres dentro del dominio. También incluye herramientas de administración, como DNS Manager

#Crea un nuevo bosque de Active Directory (Install-ADDSForest) "miejemplo.local". ForestMode: WinThreshold -> Modo funcional del bosque (la versión más reciente disponible). DomainMode: WinThreshold → Modo funcional del dominio. -InstallDNS → Instala el servicio DNS automáticamente. SafeModeAdministratorPassword → Define la contraseña 
Install-ADDSForest -DomainName "miejemplo.local" -ForestMode WinThreshold -DomainMode WinThreshold -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd1" -AsPlainText -Force) -Confirm:$false 


$context = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()    #Obtiene el contexto del bosque de Active Directory (GetCurrentForest)
$context.UpnSuffixes.Add("midominiodeAzure.com")                                    #Agrega el sufijo "midominiodeAzure.com" para permitir autenticación de usuarios con ese dominio.
Write-Output "Sufijo UPN agregado correctamente."                                   #Output de confirmación


$gpoPath = "C:\\Windows\\SYSVOL\\domain\\Policies"                                  #Define la ruta donde se almacenan las GPO (SYSVOL\\domain\\Policies)
New-Item -Path "$gpoPath\\GPO-Seguridad" -ItemType Directory                        #Crea la carpeta para almacenar configuraciones específicas: "GPO-Seguridad"
New-Item -Path "$gpoPath\\GPO-Restricciones" -ItemType Directory                    #Crea la carpeta para almacenar configuraciones específicas: "GPO-Restricciones"
    
Import-Module GroupPolicy                                                           #Importa el módulo de Group Policy para manejar políticas de grupo
New-GPO -Name "BloquearUSB"                                                         #Crea una nueva GPO con el nombre "BloquearUSB"
New-GPLink -Name "BloquearUSB" -Target "DC=miejemplo,DC=local"                      #Asocia la GPO (New-GPLink) al dominio "miejemplo.local" (DC=miejemplo,DC=local)
Set-GPRegistryValue -Name "BloquearUSB" -Key "HKLM\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR" -ValueName "Start" -Type DWORD -Value 4  #Modifica el registro de Windows, estableciendo: "HKLM\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR" → Ruta del servicio de almacenamiento USB. Start = 4 → Deshabilita completamente los dispositivos USB en la computadora.
