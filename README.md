<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-avs-privatecloud

This repo is used for the Azure Verified Modules version of an Azure VMWare Solution Private Cloud resource.  It includes definitions for the following common AVM interface types: Tags, Locks, Resource Level Role Assignments, Diagnostic Settings, Managed Identity, and Customer Managed Keys.

It leverages both the AzAPI and AzureRM providers to implement the child-level resources.

> **\_NOTE:\_**  This module is not currently fully idempotent. Because run commands are used to implement the configuration of identity sources and run-commands don't have an effective data provider to do standard reads, we currently redeploy the run-command resource to get the identity provider state. Based on the output of the read, the delete and configure resources are also re-run and either set/update the identity values or run a second and/or third Get call to avoid making unnecessary changes.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>=1.9.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (>=1.9.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.71.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0)

- <a name="provider_time"></a> [time](#provider\_time)

## Resources

The following resources are used by this module:

- [azapi_resource.clusters](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.configure_identity_sources](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.current_status_identity_sources](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.dns_forwarder_zones](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.globalreach_connections](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.hcx_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.hcx_keys](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.remove_existing_identity_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.srm_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this_private_cloud](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.vr_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource_action.dns_service](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_update_resource.customer_managed_key](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) (resource)
- [azapi_update_resource.managed_identity](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) (resource)
- [azurerm_express_route_connection.avs_private_cloud_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_connection) (resource)
- [azurerm_management_lock.this_private_cloud](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this_private_cloud_diags](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this_private_cloud](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_virtual_network_gateway_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) (resource)
- [azurerm_vmware_express_route_authorization.this_authorization_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vmware_express_route_authorization) (resource)
- [azurerm_vmware_netapp_volume_attachment.attach_datastores](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vmware_netapp_volume_attachment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [random_password.nsxt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_password.vcenter](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [time_sleep.wait_120_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azapi_resource_action.avs_dns](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azapi_resource_action.sddc_creds](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azapi_resource_list.avs_run_command_executions](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_list) (data source)
- [azapi_resource_list.valid_run_commands_microsoft_avs](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_list) (data source)
- [azurerm_key_vault.this_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_resource_group.sddc_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [azurerm_vmware_private_cloud.this_private_cloud](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/vmware_private_cloud) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_avs_network_cidr"></a> [avs\_network\_cidr](#input\_avs\_network\_cidr)

Description: The full /22 or larger network CIDR summary for the private cloud managed components. This range should not intersect with any IP allocations that will be connected or visible to the private cloud.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name to use when creating the avs sddc private cloud.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: The sku value for the AVS SDDC management cluster nodes. Valid values are av20, av36, av36t, av36pt, av52, av64.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_arc_enabled"></a> [arc\_enabled](#input\_arc\_enabled)

Description: Enable the ARC addon toggle value

Type: `bool`

Default: `false`

### <a name="input_clusters"></a> [clusters](#input\_clusters)

Description:     This object describes additional clusters in the private cloud in addition to the management cluster. The map key will be used as the cluster name  
    map(object({  
      cluster\_node\_count = (required) - Integer number of nodes to include in this cluster between 3 and 16  
      sku\_name           = (required) - String for the sku type to use for the cluster nodes. Changing this forces a new cluster to be created  
    
    Example Input:
    ```terraform
       cluster1 = {
        cluster_node_count = 3
        sku_name           = "av36p"
       }
    
```

Type:

```hcl
map(object({
    cluster_node_count = number
    sku_name           = string
  }))
```

Default: `{}`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description:     This object defines the customer managed key details to use when encrypting the VSAN datastore.

    Example Inputs:
    ```terraform
      {
        key_vault_resource_id = azurerm_key_vault.example.id
        key_name              = azurerm_key_vault_key.example.name
        key_version           = azurerm_key_vault_key.example.version
      }
    
```

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
  })
```

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:   This map object is used to define the diagnostic settings on the virtual machine.  This functionality does not implement the diagnostic settings extension, but instead can be used to configure sending the vm metrics to one of the standard targets.  
  map(object({  
    name                                     = (required) - Name to use for the Diagnostic setting configuration.  Changing this creates a new resource  
    log\_categories\_and\_groups                = (Optional) - List of strings used to define log categories and groups. Currently not valid for the VM resource  
    metric\_categories                        = (Optional) - List of strings used to define metric categories. Currently only AllMetrics is valid  
    log\_analytics\_destination\_type           = (Optional) - Valid values are null, AzureDiagnostics, and Dedicated.  Defaults to null  
    workspace\_resource\_id                    = (Optional) - The Log Analytics Workspace Azure Resource ID when sending logs or metrics to a Log Analytics Workspace  
    storage\_account\_resource\_id              = (Optional) - The Storage Account Azure Resource ID when sending logs or metrics to a Storage Account  
    event\_hub\_authorization\_rule\_resource\_id = (Optional) - The Event Hub Namespace Authorization Rule Resource ID when sending logs or metrics to an Event Hub Namespace  
    event\_hub\_name                           = (Optional) - The Event Hub name when sending logs or metrics to an Event Hub  
    marketplace\_partner\_resource\_id          = (Optional) - The marketplace partner solution Azure Resource ID when sending logs or metrics to a partner integration
  }))

  ```terraform
  Example Input:
    diagnostic_settings = {
      nic_diags = {
        name                  = module.naming.monitor_diagnostic_setting.name_unique
        workspace_resource_id = azurerm_log_analytics_workspace.this_workspace.id
        metric_categories     = ["AllMetrics"]
      }
    }
```

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), [])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, null)
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_dns_forwarder_zones"></a> [dns\_forwarder\_zones](#input\_dns\_forwarder\_zones)

Description:     Map of string objects describing one or more dns forwarder zones for NSX within the private cloud. Up to 5 additional forwarder zone can be configured.   
    This is primarily useful for identity source configurations or in cases where NSX DHCP is providing DNS configurations.  
    map(object({  
    display\_name   = (Required) - The display name for the new forwarder zone being created.  Commonly this aligns with the domain name.  
    dns\_server\_ips = (Required) - A list of up to 3 IP addresses where zone traffic will be forwarded.  
    domain\_names   = (Required) - A list of domain names that will be forwarded as part of this zone.  
    revision       = (Optional) - NSX Revision number.  Defaults to 0  
    source\_ip      = (Optional) - Source IP of the DNS zone.  Defaults to an empty string.  
  }))

  Example Input:
    ```terraform
    {
      exr_region_1 = {
        expressroute_gateway_resource_id                     = "<expressRoute Gateway Resource ID>"
        peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
      }
    }

```

Type:

```hcl
map(object({
    display_name               = string
    dns_server_ips             = list(string)
    domain_names               = list(string)
    revision                   = optional(number, 0)
    source_ip                  = optional(string, "")
    add_to_default_dns_service = optional(bool, false)
  }))
```

Default: `{}`

### <a name="input_enable_stretch_cluster"></a> [enable\_stretch\_cluster](#input\_enable\_stretch\_cluster)

Description: Set this value to true if deploying an AVS stretch cluster.

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_expressroute_auth_keys"></a> [expressroute\_auth\_keys](#input\_expressroute\_auth\_keys)

Description: This set of strings defines one or more names to creating new expressroute authorization keys for the private cloud

Type: `set(string)`

Default: `[]`

### <a name="input_expressroute_connections"></a> [expressroute\_connections](#input\_expressroute\_connections)

Description:     Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.  
    map(object({  
    vwan\_hub\_connection                                  = (Optional) - Set this to true if making a connection to a VWAN hub.  Leave as false if connecting to an ExpressRoute gateway in a virtual network hub.  
    expressroute\_gateway\_resource\_id                     = (Required) - The Azure Resource ID for the ExpressRoute gateway where the connection will be made.  
    authorization\_key\_name                               = (Optional) - The authorization key name that should be used from the auth key map. If no key is provided a name will be generated from the map key.  
    fast\_path\_enabled                                    = (Optional) - Should fast path gateway bypass be enabled. There are sku and cost considerations to be aware of when enabling fast path. Defaults to false  
    routing\_weight                                       = (Optional) - The routing weight value to use for this connection.  Defaults to 0.  
    enable\_internet\_security                             = (Optional) - Set this to true if connecting to a secure VWAN hub and you want the hub NVA to publish a default route to AVS.  
    routing                                              = optional(map(object({  
      associated\_route\_table\_resource\_id = (Optional) - The Azure Resource ID of the Virtual Hub Route Table associated with this Express Route Connection.  
      inbound\_route\_map\_resource\_id      = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for inbound learned routes  
      outbound\_route\_map\_resource\_id     = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for outbound advertised routes  
      propagated\_route\_table = object({   
        labels = (Optional) - The list of labels for route tables where the routes will be propagated to  
        ids    = (Optional) - The list of Azure Resource IDs for route tables where the routes will be propagated to
      })
    })), null)
  }))

  Example Input:
    ```terraform
    {
      exr_region_1 = {
        expressroute_gateway_resource_id                     = "<expressRoute Gateway Resource ID>"
        peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
      }
    }

```

Type:

```hcl
map(object({
    vwan_hub_connection              = optional(bool, false)
    expressroute_gateway_resource_id = string
    authorization_key_name           = optional(string, null)
    fast_path_enabled                = optional(bool, false)
    routing_weight                   = optional(number, 0)
    enable_internet_security         = optional(bool, false)
    routing = optional(map(object({
      associated_route_table_resource_id = optional(string, null)
      inbound_route_map_resource_id      = optional(string, null)
      outbound_route_map_resource_id     = optional(string, null)
      propagated_route_table = optional(object({
        labels = optional(list(string), [])
        ids    = optional(list(string), [])
      }), {})
    })), {})
  }))
```

Default: `{}`

### <a name="input_global_reach_connections"></a> [global\_reach\_connections](#input\_global\_reach\_connections)

Description:     Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.  
    map(object({  
      authorization\_key                     = (Required) - The authorization key from the peer expressroute   
      peer\_expressroute\_circuit\_resource\_id = (Optional) - Identifier of the ExpressRoute Circuit to peer within the global reach connection
      })
    )

  Example Input:
    ```terraform
    {
      gr_region_1 = {
        authorization_key                     = "<auth key value>"
        peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
      }
    }

```

Type:

```hcl
map(object({
    authorization_key                     = string
    peer_expressroute_circuit_resource_id = string
  }))
```

Default: `{}`

### <a name="input_hcx_enabled"></a> [hcx\_enabled](#input\_hcx\_enabled)

Description: Enable the HCX addon toggle value

Type: `bool`

Default: `false`

### <a name="input_hcx_key_names"></a> [hcx\_key\_names](#input\_hcx\_key\_names)

Description: list of key names to use when generating hcx site activation keys. Requires HCX add\_on to be enabled.

Type: `list(string)`

Default: `[]`

### <a name="input_hcx_license_type"></a> [hcx\_license\_type](#input\_hcx\_license\_type)

Description: Describes which HCX license option to use.  Valid values are Advanced or Enterprise.

Type: `string`

Default: `"Advanced"`

### <a name="input_internet_enabled"></a> [internet\_enabled](#input\_internet\_enabled)

Description: Configure the internet SNAT option to be on or off. Defaults to off.

Type: `bool`

Default: `false`

### <a name="input_ldap_user"></a> [ldap\_user](#input\_ldap\_user)

Description: The username for the domain user the vcenter will use to query LDAP(s)

Type: `string`

Default: `null`

### <a name="input_ldap_user_password"></a> [ldap\_user\_password](#input\_ldap\_user\_password)

Description: Password to use for the domain user the vcenter will use to query LDAP(s)

Type: `string`

Default: `null`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where this and supporting resources should be deployed.  Defaults to the Resource Groups location if undefined.

Type: `string`

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:     "The lock level to apply to this virtual machine and all of it's child resources. The default value is none. Possible values are `None`, `CanNotDelete`, and `ReadOnly`. Set the lock value on child resource values explicitly to override any inherited locks."

    Example Inputs:
    ```terraform
    lock = {
      name = "lock-{resourcename}" # optional
      type = "CanNotDelete"
    }
    
```

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
```

Default: `{}`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description: resource doesn't support user-assigned managed identities.

Type:

```hcl
object({
    system_assigned = optional(bool, false)
  })
```

Default: `{}`

### <a name="input_management_cluster_size"></a> [management\_cluster\_size](#input\_management\_cluster\_size)

Description: The number of nodes to include in the management cluster. The minimum value is 3 and the current maximum is 16.

Type: `number`

Default: `3`

### <a name="input_netapp_files_datastores"></a> [netapp\_files\_datastores](#input\_netapp\_files\_datastores)

Description:     This map of objects describes one or more netapp volume attachments.  The map key will be used for the datastore name and should be unique.

    map(object({  
      netapp\_volume\_resource\_id = (required) - The azure resource ID for the Azure Netapp Files volume being attached to the cluster nodes.  
      cluster\_names             = (required) - A set of cluster name(s) where this volume should be attached
    }))

    Example Input:
    ```terraform
      anf_datastore_cluster1 = {
        netapp_volume_resource_id = azurerm_netapp_volume.test.id
        cluster_names             = ["Cluster-1"]
      }
    
```

Type:

```hcl
map(object({
    netapp_volume_resource_id = string
    cluster_names             = set(string)
  }))
```

Default: `{}`

### <a name="input_nsxt_password"></a> [nsxt\_password](#input\_nsxt\_password)

Description: The password value to use for the cloudadmin account password in the local domain in nsxt. If this is left as null a random password will be generated for the deployment

Type: `string`

Default: `null`

### <a name="input_primary_zone"></a> [primary\_zone](#input\_primary\_zone)

Description: This value represents the zone for deployment in a standard deployment or the primary zone in a stretch cluster deployment. Defaults to null to let Azure select the zone

Type: `number`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A list of role definitions and scopes to be assigned as part of this resources implementation.  Two forms are supported. Assignments against this virtual machine resource scope and assignments to external resource scopes using the system managed identity.  
  list(object({  
    principal\_id                               = (optional) - The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.  
    role\_definition\_id\_or\_name                 = (Optional) - The Scoped-ID of the Role Definition or the built-in role name. Changing this forces a new resource to be created. Conflicts with role\_definition\_name   
    condition                                  = (Optional) - The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.  
    condition\_version                          = (Optional) - The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.  
    description                                = (Optional) - The description for this Role Assignment. Changing this forces a new resource to be created.  
    skip\_service\_principal\_aad\_check           = (Optional) - If the principal\_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal\_id is a Service Principal identity. Defaults to true.  
    delegated\_managed\_identity\_resource\_id     = (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.  
  }))

  Example Inputs:

  ```terraform
    #typical assignment example. It is also common for the scope resource ID to be a terraform resource reference like azurerm_resource_group.example.id
    role_assignments = {
      role_assignment_1 = {
        #assign a built-in role to the virtual machine
        role_definition_id_or_name                 = "Storage Blob Data Contributor"
        principal_id                               = data.azuread_client_config.current.object_id
        description                                = "Example for assigning a role to an existing principal for the virtual machine scope"        
      }
    }
```

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, true)
    delegated_managed_identity_resource_id = optional(string)
    }
  ))
```

Default: `{}`

### <a name="input_secondary_zone"></a> [secondary\_zone](#input\_secondary\_zone)

Description: This value represents the secondary zone in a stretch cluster deployment.

Type: `number`

Default: `null`

### <a name="input_srm_enabled"></a> [srm\_enabled](#input\_srm\_enabled)

Description: Enable the SRM addon toggle value

Type: `bool`

Default: `false`

### <a name="input_srm_license_key"></a> [srm\_license\_key](#input\_srm\_license\_key)

Description: The license key to use for the SRM installation

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Map of tags to be assigned to this resource

Type: `map(any)`

Default: `{}`

### <a name="input_vcenter_identity_sources"></a> [vcenter\_identity\_sources](#input\_vcenter\_identity\_sources)

Description:   A map of objects representing a list of 0-2 identity sources for configuring LDAP or LDAPs on the private cloud. The map key will be used as the name value for the identity source.

    map(object({  
      alias                   = (Required) - The domains NETBIOS name  
      base\_group\_dn           = (Required) - The base distinguished name for groups  
      base\_user\_dn            = (Required) - The base distinguished name for users  
      domain                  = (Required) - The fully qualified domain name for the identity source  
      group\_name              = (Optional) - The name of the LDAP group that will be added to the cloudadmins role  
      name                    = (Required) - The name to give the identity source  
      password                = (Required) - Password to use for the domain user the vcenter will use to query LDAP(s)  
      primary\_server          = (Required) - The URI of the primary server. (Ex: ldaps://server.domain.local:636)  
      secondary\_server        = (Optional) - The URI of the secondary server. (Ex: ldaps://server.domain.local:636)  
      ssl                     = (Optional) - Determines if ldap is configured to use ssl. Default to Enabled, valid values are "Enabled" and "Disabled"
    }))

    Example Input:
    ```terraform
      {
        test.local = {
          alias                   = "test.local"
          base_group_dn           = "dc=test,dc=local"
          base_user_dn            = "dc=test,dc=local"
          domain                  = "test.local"
          name                    = "test.local"
          primary_server          = "ldaps://dc01.testdomain.local:636"
          secondary_server        = "ldaps://dc02.testdomain.local:636"
          ssl                     = "Enabled"
        }
      }
```

Type:

```hcl
map(object({
    alias            = string
    base_group_dn    = string
    base_user_dn     = string
    domain           = string
    group_name       = optional(string, null)
    name             = string
    primary_server   = string
    secondary_server = optional(string, null)
    ssl              = optional(string, "Enabled")
    timeout          = optional(string, "10m")
  }))
```

Default: `{}`

### <a name="input_vcenter_password"></a> [vcenter\_password](#input\_vcenter\_password)

Description: The password value to use for the cloudadmin account password in the local domain in vcenter. If this is left as null a random password will be generated for the deployment

Type: `string`

Default: `null`

### <a name="input_vr_enabled"></a> [vr\_enabled](#input\_vr\_enabled)

Description: Enable the Vsphere Replication (VR) addon toggle value

Type: `bool`

Default: `false`

### <a name="input_vrs_count"></a> [vrs\_count](#input\_vrs\_count)

Description: The total number of vsphere replication servers to deploy

Type: `number`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_credentials"></a> [credentials](#output\_credentials)

Description: n/a

### <a name="output_id"></a> [id](#output\_id)

Description: n/a

### <a name="output_identity"></a> [identity](#output\_identity)

Description: n/a

### <a name="output_private_cloud"></a> [private\_cloud](#output\_private\_cloud)

Description: n/a

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->