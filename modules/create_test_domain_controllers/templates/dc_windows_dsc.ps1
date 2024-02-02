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

[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ("$env:ACTIVEDIRECTORYNETBIOS\$env:ADMINUSERNAME", (ConvertTo-SecureString "$env:ADMINPASSWORD" -AsPlainText -Force))
[pscredential]$ldapUserPassword = New-Object System.Management.Automation.PSCredential("$env:ACTIVEDIRECTORYNETBIOS\$env:LDAPUSER", (ConvertTo-SecureString "$env:LDAPUSERPASSWORD" -AsPlainText -Force))
[pscredential]$testAdminPassword = New-Object System.Management.Automation.PSCredential("$env:ACTIVEDIRECTORYNETBIOS\$env:TESTADMIN", (ConvertTo-SecureString "$env:TESTADMINPASSWORD" -AsPlainText -Force))
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
        #Add the dns feature
        WindowsFeature 'dns'
        {
            Name                 = 'dns'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }
        #Add the RSAT tools for DNS
        WindowsFeature 'rsat-dns-server'
        {
            Name                 = 'rsat-dns-server'
            Ensure               = 'Present'
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
        #configure the DNS forwarder Addresses to point to Azure and Google DNS servers
        DnsServerForwarder 'SetForwarders'
        {
            IsSingleInstance = 'Yes'
            IPAddresses      = @('8.8.8.8', '168.63.129.16')
            UseRootHint      = $false
            DependsOn        = "[WindowsFeature]dns"
        }
        #Configure the Domain details
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
        #Wait for the Domain to be configured
        WaitForADDomain 'thisDomain'
        {
            DomainName = $Node.ActiveDirectoryFQDN
        }        
        # Install the ADCS Certificate Authority
        WindowsFeature ADCSCA {
            Name      = 'ADCS-Cert-Authority'
            Ensure    = 'Present'
            DependsOn = '[WaitForADDomain]thisDomain' 
        }        
        # Configure the CA as Standalone Enterprise Root CA
        ADCSCertificationAuthority ConfigCA
        {
            Ensure = 'Present'
            CAType = 'EnterpriseRootCA'
            CACommonName = $Node.CACommonName
            CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 20
            CryptoProviderName = 'RSA#Microsoft Software Key Storage Provider'
            HashAlgorithmName = 'SHA256'
            KeyLength = 4096
            DependsOn = '[WindowsFeature]ADCSCA'
            IsSingleInstance = 'Yes' 
            Credential = $credObject
        }
        #Install the RSAT tools of Certificate Services
        WindowsFeature RSAT-ADCS 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
            DependsOn = '[WindowsFeature]ADCSCA' 
        } 
        #Install the RSAT tools for ADCS mgmt
        WindowsFeature RSAT-ADCS-Mgmt 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS-Mgmt' 
            DependsOn = '[WindowsFeature]ADCSCA' 
        } 

        #create a regular user account for LDAP lookups
        ADUser 'ldapUser'
        {
            PsDscRunAsCredential = $credObject
            Ensure     = 'Present'
            UserName   = $Node.ldapUser
            Password   = $Node.ldapUserPassword
            DomainName = $Node.ActiveDirectoryFQDN
            Path       = "CN=Users,$env:CADistinguishedNameSuffix"
            PasswordNeverExpires = $true
            DependsOn = '[WindowsFeature]ADCSCA' 
        }

        #create a regular user account for LDAP lookups
        ADUser 'testAdmin'
        {
            PsDscRunAsCredential = $credObject
            Ensure     = 'Present'
            UserName   = $Node.testAdmin
            Password   = $Node.testAdminPassword 
            DomainName = $Node.ActiveDirectoryFQDN
            Path       = "CN=Users,$env:CADistinguishedNameSuffix"
            PasswordNeverExpires = $true
            DependsOn = '[WindowsFeature]ADCSCA' 
        }

        ADGroup 'vmwareAdmins' 
        {
            PsDscRunAsCredential = $credObject
            GroupName = $Node.adminGroupName
            GroupScope = 'Global'
            Category = 'Security'
            Path = "CN=Users,$env:CADistinguishedNameSuffix"
            DependsOn = '[ADUser]testAdmin' 
            MembershipAttribute = 'DistinguishedName'
            Members = @(
                "CN=" + $Node.testAdmin + ",CN=Users,$env:CADistinguishedNameSuffix"
            )

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
            CACommonName              = $env:CACOMMONNAME
            CADistinguishedNameSuffix = $env:CADISTINGUISHEDNAMESUFFIX
            ldapUser                  = $env:LDAPUSER
            ldapUserPassword          = $ldapUserPassword
            testAdmin                 = $env:TESTADMIN
            testAdminPassword         = $testAdminPassword
            adminGroupName            = $env:ADMINGROUPNAME
        }
    ) 
}

dc -ConfigurationData $cd
Start-dscConfiguration -Path ./dc -Force

