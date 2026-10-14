# Create Test Netapp Volume

This module configures an Azure Netapp Files (ANF) account, pool and volume configured for use by AVS testing.

## Provider migration

The unused AzAPI provider requirement has been removed. Calls that explicitly pass `azapi` must remove
that entry from this helper's `providers` map; remove the map if it becomes empty. Keep any `azurerm`
mapping, including aliases. Calls without an explicit provider map need no change. Resource addresses
are unchanged; no state migration is required.
