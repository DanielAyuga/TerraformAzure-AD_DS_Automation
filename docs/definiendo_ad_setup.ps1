## Definiendo ad_setup.ps1

#Configuración BASICA de AD-DS

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools   #Instala Active Directory Domain Services (ADDS) para permitir la creación de un dominio incluidas herramientas de administración como ADUC (Active Directory Users and Computers)
Install-WindowsFeature RSAT-AD-PowerShell                                 #Instala las herramientas de administración remota (RSAT) para Active Directory en PowerShell. Esto permite ejecutar comandos de AD directamente en PowerShell.
Import-Module ActiveDirectory                                             #Carga el módulo de Active Directory en PowerShell, habilitando el uso de cmdlets como Install-ADDSForest o New-GPO
Install-WindowsFeature -Name DNS -IncludeManagementTools                  #Instala el servicio DNS, para resolver nombres dentro del dominio. También incluye herramientas de administración, como DNS Manager

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\post_ad_setup.ps1"           #Definimos que $action es una nueva tarea que ejecuta el script en Poweshell
$trigger = New-ScheduledTaskTrigger -AtStartup                                                               #El disparador será el inicio de la VM
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount                           #Crea un objeto que representa el usuario bajo el cual se ejecutará la tarea bajo la cuenta SYSTEM, que tiene privilegios administrativos en la máquina. La tarea se ejecutará en segundo plano sin necesidad de que un usuario inicie sesión
Register-ScheduledTask -TaskName "PostADDSConfig" -Action $action -Trigger $trigger -Principal $principal    #Registra la tarea programada con el nombre "PostADDSConfig" y usa las variables previamente definidas

#Crea un nuevo bosque de Active Directory (Install-ADDSForest) "miejemplo.local". ForestMode: WinThreshold -> Modo funcional del bosque (la versión más reciente disponible). DomainMode: WinThreshold → Modo funcional del dominio. -InstallDNS → Instala el servicio DNS automáticamente. SafeModeAdministratorPassword → Define la contraseña 
Install-ADDSForest -DomainName "miejemplo.local" -ForestMode WinThreshold -DomainMode WinThreshold -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd1" -AsPlainText -Force) -Confirm:$false 
