#Instalación de Active Directory Domain Services (AD DS)
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Creación del bosque y dominio en Active Directory (con un dominio interno)
Install-ADDSForest -DomainName "miejemplo.local" -ForestMode WinThreshold -DomainMode WinThreshold -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd1" -AsPlainText -Force) -Confirm:$false

# Agregar el sufijo UPN para sincronización con Entra ID
$context = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$context.UpnSuffixes.Add("danielayugachaconoutlook.onmicrosoft.com")
Write-Output "✔️ Sufijo UPN agregado correctamente."

# Configuración de políticas de grupo (GPO) en SYSVOL
$gpoPath = "C:\\Windows\\SYSVOL\\domain\\Policies"
New-Item -Path "$gpoPath\\GPO-Seguridad" -ItemType Directory
New-Item -Path "$gpoPath\\GPO-Restricciones" -ItemType Directory
    
Import-Module GroupPolicy
New-GPO -Name "BloquearUSB"
New-GPLink -Name "BloquearUSB" -Target "DC=miejemplo,DC=local"
Set-GPRegistryValue -Name "BloquearUSB" -Key "HKLM\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR" -ValueName "Start" -Type DWORD -Value 4
