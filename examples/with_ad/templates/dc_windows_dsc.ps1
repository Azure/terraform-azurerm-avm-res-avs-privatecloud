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

Configuration dc {
   
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName DnsServerDsc
    Import-DscResource -ModuleName SecurityPolicyDsc
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DSCResource -Name WindowsFeature

    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($Node.ADMINUSERNAME, (ConvertTo-SecureString $Node.ADMINPASSWORD -AsPlainText -Force))

    Node localhost
    {
        #Add the containers and hypervisor features and reboot if needed 
        WindowsFeature 'ad-domain-services'
        {
            Name                 = 'ad-domain-services'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }

        WindowsFeature 'dns'
        {
            Name                 = 'dns'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }

        WindowsFeature 'rsat-dns-server'
        {
            Name                 = 'rsat-dns-server'
            Ensure               = 'Present'
        }

        WindowsFeature 'rsat-adds'
        {
            Name                 = 'rsat-adds'
            Ensure               = 'Present'
        }

        WindowsFeature 'rsat-ad-powershell'
        {
            Name                 = 'rsat-ad-powershell'
            Ensure               = 'Present'
        }

        DnsServerForwarder 'SetForwarders'
        {
            IsSingleInstance = 'Yes'
            IPAddresses      = @('8.8.8.8', '168.63.129.16')
            UseRootHint      = $false
            DependsOn        = "[WindowsFeature]dns"
        }

        ADDomain 'thisDomain'
        {
            DomainName                    = $Node.ActiveDirectoryFQDN
            Credential                    = $credObject
            SafemodeAdministratorPassword = $credObject
            ForestMode                    = 'WinThreshold'
            DomainMode                    = 'WinThreshold'
            DomainNetBiosName             = $Node.ActiveDirectoryNETBIOS
            DependsOn                     = "[WindowsFeature]ad-domain-services"
        } 
        
        WaitForADDomain 'thisDomain'
        {
            DomainName = $Node.ActiveDirectoryFQDN
        }
        
    }
}

$cd = @{
    AllNodes = @(    
        @{ 
            NodeName               = "localhost"
            CertificateFile        = "C:\temp\dsc64.cer"
            Thumbprint             = $env:THUMBPRINT
            AdminUsername          = $env:ADMINUSERNAME
            AdminPassword          = $env:ADMINPASSWORD
            ActiveDirectoryFQDN    = $env:ACTIVEDIRECTORYFQDN
            ActiveDirectoryNETBIOS = $env:ACTIVEDIRECTORYNETBIOS

        }
    ) 
}
dc -ConfigurationData $cd
Start-dscConfiguration -Path ./dc -Force

