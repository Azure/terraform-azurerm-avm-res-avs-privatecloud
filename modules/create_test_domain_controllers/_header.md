# Create Test Domain Controllers

This module creates two windows virtual machines configured as domain controllers for use in testing the identity provider configuration. The VM's include Active Directory Certificate Services and DNS server and are configured to support LDAPs. The module also modifies the DNS configuration in the Vnet to point at the primary DC for DNS. 

ARM resource ID inputs are validated with AzAPI. Existing VM provider inheritance and partial caller
provider maps are retained.
