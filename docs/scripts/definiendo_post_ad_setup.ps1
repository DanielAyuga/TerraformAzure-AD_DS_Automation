## Definiendo post_ad_setup.ps1

Start-Sleep -Seconds 60       #Pausa la ejecucion del script 60 segundos. Damos tiempo a que el sistema o algunos procesos acaben de iniciarse

# Agregar el sufijo UPN
$context = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() #Obtenemos el objeto que representa el bosque de Active Directory en el que se encuentra el equipo y lo asignamos a la variable $context para poder operar sobre él posteriormente
$context.UpnSuffixes.Add("midominiodeAzure.com")                                 #Añadimos un nuevo sufijo de correo principal de usuario al bosque, permitiendo una futura sincronización con Azure

# Configuración de políticas de grupo (GPO) en SYSVOL
$gpoPath = "C:\\Windows\\SYSVOL\\domain\\Policies"                               #Asigna a la variable $gpoPath la ruta base donde se almacenan las políticas de grupo en el controlador de dominio
New-Item -Path "$gpoPath\\GPO-Seguridad" -ItemType Directory                     #Crea una nueva carpeta llamada GPO-Seguridad dentro de la ruta definida
New-Item -Path "$gpoPath\\GPO-Restricciones" -ItemType Directory                 #Crea una nueva carpeta llamada GPO-Restricciones dentro de la ruta definida

# Creación de GPO
Import-Module GroupPolicy                                                        #Carga el módulo de PowerShell para crear, modificar y vincular GPOs
New-GPO -Name "BloquearUSB"                                                      #Creamos una nueva GPO denominada "BloquearUSB"
New-GPLink -Name "BloquearUSB" -Target "DC=miejemplo,DC=local"                   #Vinculamos la GPO "BloquearUSB" al contenedor de Active Directory identificado por "DC=miejemplo,DC=local"
Set-GPRegistryValue -Name "BloquearUSB" -Key "HKLM\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR" -ValueName "Start" -Type DWORD -Value 4  #Establecemos una configuración específica en el registro. Deshabilitamos el servicio de almacenamiento USB en el sistema

New-ADOrganizationalUnit -Name "Usuarios" -Path "DC=miejemplo,DC=local"          #Creamos una nueva unidad organizativa llamada "Usuarios" directamente en el dominio "miejemplo.local"

# Usuarios                                                                                 #Listado de usarios a dar de alta en formato json
$users = @(
    @{ Name = 'Carlos Sanchez';   Username = 'csanchez';   Password = 'P@ssw0rd1' },
    @{ Name = 'Ana Rodriguez';      Username = 'arodriguez';  Password = 'P@ssw0rd2' },
    @{ Name = 'Miguel Lopez';       Username = 'mlopez';      Password = 'P@ssw0rd3' },
    @{ Name = 'Elena Fernandez';    Username = 'efernandez';  Password = 'P@ssw0rd4' },
    @{ Name = 'Javier Gomez';       Username = 'jgomez';      Password = 'P@ssw0rd5' }
)

# Importar el módulo de Active Directory
Import-Module ActiveDirectory                                                             #Importamos el módulo de ActiveDirectory

# Crear usuarios en AD DS
foreach ($user in $users) {                                                               #Iteramos sobre cada usuario del listado estableciendoles determinados parámetros
    New-ADUser -Name $user.Name `
               -SamAccountName $user.Username `
               -UserPrincipalName "$($user.Username)@miejemplo.local" `
               -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) `
               -Enabled $true `
               -Path 'OU=Usuarios,DC=miejemplo,DC=local' `
               -PassThru | Out-Null
}

# Eliminar tarea programada
Unregister-ScheduledTask -TaskName "PostADDSConfig" -Confirm:$false                       #Eliminamos la tarea que programamos en el script "ad_setup.ps1"
