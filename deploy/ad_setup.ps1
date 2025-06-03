#Instalación de Active Directory Domain Services (AD DS)
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory
Install-WindowsFeature -Name DNS -IncludeManagementTools

#Tarea programada para ejecutar otro script tras el reinicio de instalación del ADDSForest
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\post_ad_setup.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "PostADDSConfig" -Action $action -Trigger $trigger -Principal $principal

# Creación del bosque y dominio en Active Directory (con un dominio interno)
Install-ADDSForest -DomainName "miejemplo.local" -ForestMode WinThreshold -DomainMode WinThreshold -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd1" -AsPlainText -Force) -Confirm:$false
