New-Item -Path 'c:\temp' -ItemType Directory -ErrorAction SilentlyContinue
set-location -Path 'c:\temp'

$cert = Get-ChildItem -Path "cert:\LocalMachine\My\$env:THUMBPRINT"
Export-Certificate -Cert $cert -FilePath .\dsc.cer
certutil -encode dsc.cer dsc64.cer

[DSCLocalConfigurationManager()]
Configuration lcmConfig {
    Node localhost
    {
        Settings
        {
            RefreshMode = 'Push'
            ActionAfterReboot = "ContinueConfiguration"
            RebootNodeIfNeeded = $true
            ConfigurationModeFrequencyMins = 15
            CertificateID = $env:THUMBPRINT
        }
    }
}

Write-Host "Creating LCM mof"
lcmConfig -InstanceName localhost -OutputPath .\lcmConfig
Set-DscLocalConfigurationManager -Path .\lcmConfig -Verbose

[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ("$env:ACTIVEDIRECTORYNETBIOS\$env:ADMINUSERNAME", (ConvertTo-SecureString "$env:PRIMARYADMINPASSWORD" -AsPlainText -Force))
[pscredential]$credObjectLocal = New-Object System.Management.Automation.PSCredential ($env:ADMINUSERNAME, (ConvertTo-SecureString "$env:ADMINPASSWORD" -AsPlainText -Force))
$isDC = try{(get-ADDomainController).enabled} catch {$false}
$runAsCred = if ($isDC) {$credObject} else {$credObjectLocal}

$adminUser = "$env:ACTIVEDIRECTORYNETBIOS\$env:ADMINUSERNAME"
Configuration dc {
   
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName DnsServerDsc
    Import-DscResource -ModuleName SecurityPolicyDsc
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DSCResource -ModuleName ActiveDirectoryCSDsc
    Import-DSCResource -Name WindowsFeature

    #[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($Node.ADMINUSERNAME, (ConvertTo-SecureString $Node.ADMINPASSWORD -AsPlainText -Force))

    Node localhost
    {
        #prefer ipv4 over ipv6
        Registry "ipv4" 
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
            ValueName   = "DisabledComponents"
            ValueType   = "Dword"
            ValueData   = "32"
        }
        #Add the domain services feature
        WindowsFeature 'ad-domain-services'
        {
            Name                 = 'ad-domain-services'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }
        #add the RSAT tools for ADDS
        WindowsFeature 'rsat-adds'
        {
            Name                 = 'rsat-adds'
            Ensure               = 'Present'
        }
        #Add the AD DS powershell cmdlets
        WindowsFeature 'rsat-ad-powershell'
        {
            Name                 = 'rsat-ad-powershell'
            Ensure               = 'Present'
        }

        # Check if a reboot is needed before installing Exchange
        PendingReboot beforeForestCheck
        {
            Name       = 'beforeForestCheck'
            DependsOn  = '[Registry]ipv4'
        }


        WaitForADDomain 'WaitForestAvailability'
        {
            DomainName = $Node.ActiveDirectoryFQDN
            #Credential = $credObject
            RestartCount = 3


            DependsOn  = '[PendingReboot]beforeForestCheck'
        }

        #ADDomainController 'DomainControllerUsingExistingDNSServer'
        #{
        #    DomainName                    = $Node.ActiveDirectoryFQDN
        #    Credential                    = $credObject
        #    SafeModeAdministratorPassword = $credObject
        #    IsGlobalCatalog               = $true
        #    InstallDns                    = $true
        #    DependsOn                     = '[WaitForADDomain]WaitForestAvailability'
        #}


        #ADDomainController resource wasn't working on server 2022 vm in Azure, use custom script with powershell instead.
        script 'configureDomainController' {
            PsDscRunAsCredential = $runAsCred
            DependsOn            = '[WaitForADDomain]WaitForestAvailability'
            GetScript            = { return @{result = 'Installing Domain Controller' } }
            TestScript           = {                
                $returnValue = try{(get-ADDomainController).enabled} catch {$false}
                return $returnValue
            }
            SetScript            = {   
                $domain = $Using:ConfigurationData.AllNodes.ActiveDirectoryFQDN
                [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($Using:ConfigurationData.AllNodes.AdminUser, (ConvertTo-SecureString $Using:ConfigurationData.AllNodes.AdminPassword -AsPlainText -Force))
                $safePass = (ConvertTo-SecureString $Using:ConfigurationData.AllNodes.AdminPassword -AsPlainText -Force)
                Write-Host "joining domain controller to domain $domain"
                Install-ADDSDomainController `
                    -AllowDomainControllerReinstall:$true `
                    -NoGlobalCatalog:$false `
                    -CreateDnsDelegation:$false `
                    -Credential $credObject `
                    -CriticalReplicationOnly:$false `
                    -DatabasePath "C:\Windows\NTDS" `
                    -DomainName $domain `
                    -InstallDns:$true `
                    -LogPath "C:\Windows\NTDS" `
                    -NoRebootOnCompletion:$false `
                    -SiteName "Default-First-Site-Name" `
                    -SysvolPath "C:\Windows\SYSVOL" `
                    -Force:$true `
                    -SafeModeAdministratorPassword $safePass
            }
        }       
    }
}

$cd = @{
    AllNodes = @(    
        @{ 
            NodeName                  = "localhost"
            CertificateFile           = "C:\temp\dsc64.cer"
            Thumbprint                = $env:THUMBPRINT
            ActiveDirectoryFQDN       = $env:ACTIVEDIRECTORYFQDN
            ActiveDirectoryNETBIOS    = $env:ACTIVEDIRECTORYNETBIOS
            AdminUser                 = $adminUser
            AdminPassword             = $env:PRIMARYADMINPASSWORD
        }
    ) 
}

dc -ConfigurationData $cd
Start-dscConfiguration -Path ./dc -Force

