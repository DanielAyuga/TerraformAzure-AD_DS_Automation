## Definiendo post_ad_setup.ps1

# Agregar el sufijo UPN para sincronización con Entra ID
$context = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$context.UpnSuffixes.Add("midominiodeAzure.com")
Write-Output "Sufijo UPN agregado correctamente."

# Configuración de políticas de grupo (GPO) en SYSVOL
$gpoPath = "C:\\Windows\\SYSVOL\\domain\\Policies"
New-Item -Path "$gpoPath\\GPO-Seguridad" -ItemType Directory
New-Item -Path "$gpoPath\\GPO-Restricciones" -ItemType Directory
    
Import-Module GroupPolicy
New-GPO -Name "BloquearUSB"
New-GPLink -Name "BloquearUSB" -Target "DC=miejemplo,DC=local"
Set-GPRegistryValue -Name "BloquearUSB" -Key "HKLM\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR" -ValueName "Start" -Type DWORD -Value 4

#Eliminar tarea programada
Unregister-ScheduledTask -TaskName "PostADDSConfig" -Confirm:$false
