# terraform-azurerm-avm-res-avs-privatecloud

This repo is used for the Azure Verified Modules version of an Azure VMWare Solution Private Cloud resource.  It includes definitions for the following common AVM interface types: Tags, Locks, Resource Level Role Assignments, Diagnostic Settings, Managed Identity, and Customer Managed Keys. 

It leverages both the AzAPI and AzureRM providers to implement the child-level resources. 

> **_NOTE:_**  This module is not currently fully idempotent. Because run commands are used to implement the configuration of identity sources and run-commands don't have an effective data provider to do standard reads, we currently redeploy the run-command resource to get the identity provider state. Based on the output of the read, the delete and configure resources are also re-run and either set/update the identity values or run a second and/or third Get call to avoid making unnecessary changes.


