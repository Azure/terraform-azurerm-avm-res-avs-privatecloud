# terraform-azurerm-avm-res-avs-privatecloud

This repo is used for the Azure Verified Modules version of an Azure VMWare Solution Private Cloud resource.  It includes definitions for the following common AVM interface types: Tags, Locks, Resource Level Role Assignments, Diagnostic Settings, Managed Identity, and Customer Managed Keys. 

It leverages both the AzAPI and AzureRM providers to implement the child-level resources. 

> **_NOTE:_** This module uses the AzAPI provider to configure most AVS resources.  The AzAPI provider introduced breaking changes in v.1.13. which aligns with v0.5.0 and forward versions of this module.  To address this, it is required to include the following provider block in your root module. If you are using other modules that use the AzAPI provider where this feature flag hasn't been implemented, then an alias with this flag will be required for this module. This requirement will go away when the AzAPI provider releases version v2.0 with this change as the default. We will update the module and notes accordingly when that occurs.

```hcl
provider "azapi" {
  enable_hcl_output_for_data_source = true
}
```

> **_NOTE:_**  This module is not currently fully idempotent. Because run commands are used to implement the configuration of identity sources and run-commands don't have an effective data provider to do standard reads, we currently redeploy the run-command resource to get the identity provider state. Based on the output of the read, the delete and configure resources are also re-run and either set/update the identity values or run a second and/or third Get call to avoid making unnecessary changes.


