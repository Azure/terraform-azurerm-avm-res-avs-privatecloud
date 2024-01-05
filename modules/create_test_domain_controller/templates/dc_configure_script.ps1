#set environment variables
$env:THUMBPRINT = "${thumbprint}"
$env:ADMINUSERNAME = "${admin_username}"
$env:ADMINPASSWORD = (ConvertTo-SecureString "${admin_password}" -AsPlainText -Force)
$env:ACTIVEDIRECTORYFQDN = "${active_directory_fqdn}"
$env:ACTIVEDIRECTORYNETBIOS = "${active_directory_netbios}"
$env:CACOMMONNAME = "${ca_common_name}"
$env:CADISTINGUISHEDNAMESUFFIX = "${ca_distinguished_name_suffix}"
$env:LDAPUSER = "${ldap_user}"
$env:LDAPUSERPASSWORD = (ConvertTo-SecureString "${ldap_user_password}" -AsPlainText -Force)



[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "${script_url}"
$output = "c:\temp\dc_windows_dsc.ps1"
Invoke-WebRequest -Uri $url -OutFile $output

#install modules
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name ActiveDirectoryDsc -Force -AllowClobber
Install-Module -Name DnsServerDsc -Force -AllowClobber
Install-Module -Name SecurityPolicyDsc -Force -AllowClobber
Install-Module -Name ComputerManagementDsc -Force -AllowClobber
Install-Module -Name ActiveDirectoryCSDsc -Force -AllowClobber


New-Item -Path 'c:\temp' -ItemType Directory -ErrorAction SilentlyContinue
set-location -Path 'c:\temp'

#run the script file
.\dc_windows_dsc.ps1