# Agregar el sufijo UPN
$context = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$context.UpnSuffixes.Add("midominiodeAzure.com")
Write-Output "Sufijo UPN agregado correctamente."

# Configuración de políticas de grupo (GPO) en SYSVOL
$gpoPath = "C:\\Windows\\SYSVOL\\domain\\Policies"
New-Item -Path "$gpoPath\\GPO-Seguridad" -ItemType Directory
New-Item -Path "$gpoPath\\GPO-Restricciones" -ItemType Directory

# Creación de GPO
Import-Module GroupPolicy
New-GPO -Name "BloquearUSB"
New-GPLink -Name "BloquearUSB" -Target "DC=miejemplo,DC=local"
Set-GPRegistryValue -Name "BloquearUSB" -Key "HKLM\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR" -ValueName "Start" -Type DWORD -Value 4

New-ADOrganizationalUnit -Name "Usuarios" -Path "DC=miejemplo,DC=local"

# Cargar el contenido del archivo JSON
$users = Get-Content "C:\usuarios.json" | ConvertFrom-Json

# Importar el módulo de Active Directory
Import-Module ActiveDirectory

# Crear usuarios en AD DS
foreach ($user in $users) {
    New-ADUser -Name $user.Name `
               -SamAccountName $user.Username `
               -UserPrincipalName "$($user.Username)@miejemplo.local" `
               -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) `
               -Enabled $true `
               -Path "OU=Usuarios,DC=miejemplo,DC=local" `
               -PassThru | Out-Null

    Write-Output "Usuario $($user.Username) creado correctamente."
}

Write-Output "Todos los usuarios han sido creados exitosamente en Active Directory."

# Eliminar tarea programada
Unregister-ScheduledTask -TaskName "PostADDSConfig" -Confirm:$false
