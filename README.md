<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-avs-privatecloud

This repo is used for the Azure Verified Modules version of an Azure VMWare Solution Private Cloud resource.  It includes definitions for the following common AVM interface types: Tags, Locks, Resource Level Role Assignments, Diagnostic Settings, Managed Identity, and Customer Managed Keys.

It leverages both the AzAPI and AzureRM providers to implement the child-level resources.

> **\_NOTE:\_** This module uses the AzAPI provider to configure most AVS resources.  The AzAPI provider introduced breaking changes in v.1.13. which aligns with v0.5.0 and forward versions of this module.  To address this, it is required to include the following provider block in your root module. If you are using other modules that use the AzAPI provider where this feature flag hasn't been implemented, then an alias with this flag will be required for this module. This requirement will go away when the AzAPI provider releases version v2.0 with this change as the default. We will update the module and notes accordingly when that occurs.

```hcl
provider "azapi" {
  enable_hcl_output_for_data_source = true
}
```

> **\_NOTE:\_**  This module is not currently fully idempotent. Because run commands are used to implement the configuration of identity sources and run-commands don't have an effective data provider to do standard reads, we currently redeploy the run-command resource to get the identity provider state. Based on the output of the read, the delete and configure resources are also re-run and either set/update the identity values or run a second and/or third Get call to avoid making unnecessary changes.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13, != 1.13.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.106)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.11)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.106)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.6)

- <a name="provider_terraform"></a> [terraform](#provider\_terraform)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.11)

## Resources

The following resources are used by this module:

- [azapi_resource.arc_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.avs_interconnect](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.avs_private_cloud_expressroute_vnet_gateway_connection_additional](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.clusters](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.configure_identity_sources](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.dhcp](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.dns_forwarder_zones](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.globalreach_connections](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.hcx_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.hcx_keys](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.iscsi_path_network](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.public_ip](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.remove_existing_identity_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.segments](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.srm_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this_esan_attachment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this_private_cloud](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.vr_addon](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource_action.dns_service](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_resource_action.dns_service_destroy_non_empty_start](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_update_resource.customer_managed_key](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) (resource)
- [azurerm_express_route_connection.avs_private_cloud_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_connection) (resource)
- [azurerm_express_route_connection.avs_private_cloud_connection_additional](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_connection) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this_private_cloud_diags](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this_private_cloud](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_vmware_express_route_authorization.this_authorization_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vmware_express_route_authorization) (resource)
- [azurerm_vmware_netapp_volume_attachment.attach_datastores](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vmware_netapp_volume_attachment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [random_password.nsxt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_password.vcenter](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [terraform_data.rerun_get](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [time_sleep.wait_120_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azapi_resource_action.avs_dns](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azapi_resource_action.avs_gateways](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azapi_resource_action.sddc_creds](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azurerm_key_vault.this_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_resource_group.sddc_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [azurerm_vmware_private_cloud.this_private_cloud](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/vmware_private_cloud) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_avs_network_cidr"></a> [avs\_network\_cidr](#input\_avs\_network\_cidr)

Description: The full /22 or larger network CIDR summary for the private cloud managed components. This range should not intersect with any IP allocations that will be connected or visible to the private cloud.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where this and supporting resources should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name to use when creating the avs sddc private cloud.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_resource_group_resource_id"></a> [resource\_group\_resource\_id](#input\_resource\_group\_resource\_id)

Description: The resource group Azure Resource ID for the deployment resource group. Used for the AzAPI resource that deploys the private cloud.

Type: `string`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: The sku value for the AVS SDDC management cluster nodes. Valid values are av20, av36, av36t, av36pt, av52, av64.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_addons"></a> [addons](#input\_addons)

Description: Map object containing configurations for the different addon types.  Each addon type has associated fields and specific naming requirements.  A full input example is provided below.

- `Arc`- Use this exact key value for deploying the ARC extension
  - `arc_vcenter` (Optional) - The VMware vcenter resource id as a string
- `HCX` - Use this exact key value for deploying the HCX extension
  - `hcx_key_names` (Optional) - A list of key names to create HCX key names.
  - `hcx_license_type` (Optional) - The type of license to configure for HCX.  Valid values are "Advanced" and "Enterprise".
- `SRM` - Use this exact key value for deploying the SRM extension
  - `srm_license_key` (Optional) - the license key to use when enabling the SRM addon
- `VR` - Use this exact key value for deploying the VR extension
  - `vr_vrs_count` (Optional) - The Vsphere replication server count

Example Input:
```hcl
{
  Arc = {
    arc_vcenter = "<vcenter resource id>"
  }
  HCX = {
    hcx_key_names = ["key1", "key2"]
    hcx_license_type = "Enterprise"
  }
  SRM = {
    srm_license_key = "<srm license key value>"
  }
  VR = {
    vr_vrs_count = 2
  }
}
```

Type:

```hcl
map(object({
    arc_vcenter      = optional(string)
    hcx_key_names    = optional(list(string), [])
    hcx_license_type = optional(string, "Enterprise")
    srm_license_key  = optional(string)
    vr_vrs_count     = optional(number, 0)
  }))
```

Default: `{}`

### <a name="input_avs_interconnect_connections"></a> [avs\_interconnect\_connections](#input\_avs\_interconnect\_connections)

Description: Map of string objects describing one or more private cloud interconnect connections for private clouds in the same region.  The map key will be used for the connection name.

- `<map key>` - use a custom map key to use as the name for the interconnect connection
  - `linked_private_cloud_resource_id` = (Required) - The resource ID of the private cloud on the other side of the interconnect. Must be in the same region.

Example Input:
```hcl
{
  interconnect_sddc_1 = {
    linked_private_cloud_resource_id = "<SDDC resource ID>"
  }
}
```

Type:

```hcl
map(object({
    linked_private_cloud_resource_id = string
  }))
```

Default: `{}`

### <a name="input_clusters"></a> [clusters](#input\_clusters)

Description: This object describes additional clusters in the private cloud in addition to the management cluster. The map key will be used as the cluster name

- `<map key>` - Provide a custom key name that will be used as the cluster name
  - `cluster_node_count` = (required) - Integer number of nodes to include in this cluster between 3 and 16
  - `sku_name`           = (required) - String for the sku type to use for the cluster nodes. Changing this forces a new cluster to be created

Example Input:
```hcl
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

Description: This object defines the customer managed key details to use when encrypting the VSAN datastore.

- `<map key>` - Provide a custom key value that will be used as the dhcp configuration name
  - `key_vault_resource_id` = (Required) - The full Azure resource ID of the key vault where the encryption key will be sourced from
  - `key_name`              = (Required) - The name for the encryption key
  - `key_version`           = (Optional) - The key version value for the encryption key.
  - `user_assigned_identity` = (Non-Functional) - AVS doesn't currently

Example Inputs:
```hcl
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
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_dhcp_configuration"></a> [dhcp\_configuration](#input\_dhcp\_configuration)

Description: This map object describes the DHCP configuration to use for the private cloud. It can remain unconfigured or define a RELAY or SERVER based configuration. Defaults to unconfigured. This allows for new segments to define DHCP ranges as part of their definition. Only one DHCP configuration is allowed.

- `<map key>` - Provide a custom key value that will be used as the dhcp configuration name
  - `display_name`           = (Required) - The display name for the dhcp configuration being created
  - `dhcp_type`              = (Required) - The type for the DHCP server configuration.  Valid types are RELAY or SERVER. RELAY defines a relay configuration pointing to your existing DHCP servers. SERVER configures NSX-T to act as the DHCP server.
  - `relay_server_addresses` = (Optional) - A list of existing DHCP server ip addresses from 1 to 3 servers.  Required when type is set to RELAY.  
  - `server_lease_time`      = (Optional) - The lease time in seconds for the DHCP server. Defaults to 84600 seconds.(24 hours) Only valid for SERVER configurations
  - `server_address`         = (Optional) - The CIDR range that NSX-T will use for the DHCP Server.

Example Input:
```hcl
#RELAY example
relay_config = {
  display_name           = "relay_example"
  dhcp_type              = "RELAY"
  relay_server_addresses = ["10.0.1.50", "10.0.2.50"]      
}

#SERVER example
server_config = {
  display_name      = "server_example"
  dhcp_type         = "SERVER"
  server_lease_time = 14400
  server_address    = "10.1.0.1/24"
}
```

Type:

```hcl
map(object({
    display_name           = string
    dhcp_type              = string
    relay_server_addresses = optional(list(string), [])
    server_lease_time      = optional(number, 86400)
    server_address         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: This map object is used to define the diagnostic settings on the virtual machine.  This functionality does not implement the diagnostic settings extension, but instead can be used to configure sending the vm metrics to one of the standard targets.

- `<map key>` - Provide a map key that will be used for the name of the diagnostic settings configuration  
  - `name`                                     = (required) - Name to use for the Diagnostic setting configuration.  Changing this creates a new resource
  - `log_categories_and_groups`                = (Optional) - List of strings used to define log categories and groups. Currently not valid for the VM resource
  - `log_groups`                               = (Optional) - A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`
  - `metric_categories`                        = (Optional) - List of strings used to define metric categories. Currently only AllMetrics is valid
  - `log_analytics_destination_type`           = (Optional) - Valid values are null, AzureDiagnostics, and Dedicated.  Defaults to Dedicated
  - `workspace_resource_id`                    = (Optional) - The Log Analytics Workspace Azure Resource ID when sending logs or metrics to a Log Analytics Workspace
  - `storage_account_resource_id`              = (Optional) - The Storage Account Azure Resource ID when sending logs or metrics to a Storage Account
  - `event_hub_authorization_rule_resource_id` = (Optional) - The Event Hub Namespace Authorization Rule Resource ID when sending logs or metrics to an Event Hub Namespace
  - `event_hub_name`                           = (Optional) - The Event Hub name when sending logs or metrics to an Event Hub
  - `marketplace_partner_resource_id`          = (Optional) - The marketplace partner solution Azure Resource ID when sending logs or metrics to a partner integration

Example Input:
```hcl
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
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_dns_forwarder_zones"></a> [dns\_forwarder\_zones](#input\_dns\_forwarder\_zones)

Description: Map of string objects describing one or more dns forwarder zones for NSX within the private cloud. Up to 5 additional forwarder zone can be configured. This is primarily useful for identity source configurations or in cases where NSX DHCP is providing DNS configurations.

- `<map key>` - Provide a key value that will be used as the name for the dns forwarder zone
  - `display_name`               = (Required) - The display name for the new forwarder zone being created.  Commonly this aligns with the domain name.
  - `dns_server_ips`             = (Required) - A list of up to 3 IP addresses where zone traffic will be forwarded.
  - `domain_names`               = (Required) - A list of domain names that will be forwarded as part of this zone.
  - `source_ip`                  = (Optional) - Source IP of the DNS zone.  Defaults to an empty string.  
  - `add_to_default_dns_service` = (Optional) - Set to try to associate this zone with the default DNS service.  Up to 5 zones can be linked.

Example Input:
```hcl
{
  test_local = {
    display_name               = local.test_domain_name
    dns_server_ips             = ["10.0.1.53","10.0.2.53"]
    domain_names               = ["test.local"]
    add_to_default_dns_service = true
  }
}
```

Type:

```hcl
map(object({
    display_name               = string
    dns_server_ips             = list(string)
    domain_names               = list(string)
    source_ip                  = optional(string, "")
    add_to_default_dns_service = optional(bool, false)
  }))
```

Default: `{}`

### <a name="input_elastic_san_datastores"></a> [elastic\_san\_datastores](#input\_elastic\_san\_datastores)

Description: Map of objects describing one or more elastic sAN based datastore to configure on this private cloud.

- `<map key>` - Unique map key that will be used as the prefix for the datastore attachment name.
  - `cluster_names` = (Required) - Set of cluster names that should use the volume as a datastore
  - `esan_volume_resource_id`- The Azure Resource id for the elastic san volume used to host the datastore.

Example Input:
```hcl
elastic_san_datastores = {
  esan_datastore_cluster1 = {
    esan_volume_resource_id = module.elastic_san.volumes["vg_1-volume_1"].id
    cluster_names           = ["Cluster-1"]
  }
}
```

Type:

```hcl
map(object({
    cluster_names           = set(string)
    esan_volume_resource_id = string
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

### <a name="input_expressroute_connections"></a> [expressroute\_connections](#input\_expressroute\_connections)

Description: Map of string objects describing one or more ExpressRoute connections to be configured by the private cloud. The map key will be used for the connection name.

- `<map key>` - Provide an arbitrary key value that will be used to identify this expressRoute connection
  - `name`                                 = (Required) - The name to use for the expressRoute connection.
  - `expressroute_gateway_resource_id`     = (Required) - The Azure Resource ID for the ExpressRoute gateway where the connection will be made.
  - `vwan_hub_connection`                  = (Optional) - Set this to true if making a connection to a VWAN hub.  Leave as false if connecting to an ExpressRoute gateway in a virtual network hub.
  - `authorization_key_name`               = (Optional) - The authorization key name that should be used from the auth key map. If no key is provided a name will be generated from the map key.
  - `fast_path_enabled`                    = (Optional) - Should fast path gateway bypass be enabled. There are sku and cost considerations to be aware of when enabling fast path. Defaults to false
  - `routing_weight`                       = (Optional) - The routing weight value to use for this connection.  Defaults to 0.
  - `enable_internet_security`             = (Optional) - Set this to true if connecting to a secure VWAN hub and you want the hub NVA to publish a default route to AVS.
  - `tags`                                 = (Optional) - Map of strings describing any custom tags to apply to this connection resource
  - `network_resource_group_resource_id`   = (Optional) - The resource ID of an external resource group. This is used to place the virtual network gateway connection resource with the virtual network gateway if the gateway is in a separate location.
  - `network_resource_group_location`      = (Optional) - The location of an external resource group. This is used to place the virtual network gateway connection resource with the virtual network gateway if the gateway is in a separate location.
  - `routing`                              = (Optional) - Map of objects used to describe any VWAN and Virtual Hub custom routing for this connection
    - `associated_route_table_resource_id` = (Optional) - The Azure Resource ID of the Virtual Hub Route Table associated with this Express Route Connection.
    - `inbound_route_map_resource_id`      = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for inbound learned routes
    - `outbound_route_map_resource_id`     = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for outbound advertised routes
    - `propagated_route_table` = object({
      - `labels` = (Optional) - The list of labels for route tables where the routes will be propagated to
      - `ids`    = (Optional) - The list of Azure Resource IDs for route tables where the routes will be propagated to

Example Input:
```hcl
{
  exr_region_1 = {
    expressroute_gateway_resource_id      = "<expressRoute Gateway Resource ID>"
    peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
  }
}
```

Type:

```hcl
map(object({
    name                               = string
    expressroute_gateway_resource_id   = string
    deployment_order                   = optional(number, 1)
    vwan_hub_connection                = optional(bool, false)
    authorization_key_name             = optional(string, null)
    fast_path_enabled                  = optional(bool, false)
    private_link_fast_path_enabled     = optional(bool, false)
    routing_weight                     = optional(number, 0)
    enable_internet_security           = optional(bool, false)
    tags                               = optional(map(string), {})
    network_resource_group_resource_id = optional(string, null)
    network_resource_group_location    = optional(string, null)
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

### <a name="input_extended_network_blocks"></a> [extended\_network\_blocks](#input\_extended\_network\_blocks)

Description: If using AV64 sku's in non-management clusters it is required to provide one /23 CIDR block or three /23 CIDR blocks. Provide a list of CIDR strings if planning to use AV64 nodes.

Type: `list(string)`

Default: `[]`

### <a name="input_external_storage_address_block"></a> [external\_storage\_address\_block](#input\_external\_storage\_address\_block)

Description: If using Elastic SAN or other ISCSI storage, provide an /24 CIDR range as a string for use in connecting the external storage.  Example: 10.10.0.0/24

Type: `string`

Default: `null`

### <a name="input_global_reach_connections"></a> [global\_reach\_connections](#input\_global\_reach\_connections)

Description: Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.

- `<map key>` - Provide a key value that will be used as the global reach connection name
  - `authorization_key`                     = (Required) - The authorization key from the peer expressroute
  - `peer_expressroute_circuit_resource_id` = (Optional) - Identifier of the ExpressRoute Circuit to peer within the global reach connection

Example Input:
```hcl
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

### <a name="input_internet_enabled"></a> [internet\_enabled](#input\_internet\_enabled)

Description: Configure the internet SNAT option to be on or off. Defaults to off.

Type: `bool`

Default: `false`

### <a name="input_internet_inbound_public_ips"></a> [internet\_inbound\_public\_ips](#input\_internet\_inbound\_public\_ips)

Description: This map object that describes the public IP configuration. Configure this value in the event you need direct inbound access to the private cloud from the internet. The code uses the map key as the display name for each configuration.

- `<map key>` - Provide a key value that will be used as the public ip configuration name
  - `number_of_ip_addresses` = (required) - The number of IP addresses to assign to this private cloud.

Example Input:
```hcl
public_ip_config = {
  display_name = "public_ip_configuration"
  number_of_ip_addresses = 1
}
```

Type:

```hcl
map(object({
    number_of_ip_addresses = number
  }))
```

Default: `{}`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled. This is used to configure encryption using customer managed keys.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource. Currently unused by this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_management_cluster_size"></a> [management\_cluster\_size](#input\_management\_cluster\_size)

Description: The number of nodes to include in the management cluster. The minimum value is 3 and the current maximum is 16.

Type: `number`

Default: `3`

### <a name="input_netapp_files_datastores"></a> [netapp\_files\_datastores](#input\_netapp\_files\_datastores)

Description: This map of objects describes one or more netapp volume attachments.  The map key will be used for the datastore name and should be unique.

- `<map key>` - Provide a key value that will be used as the netapp files datastore name
  - `netapp_volume_resource_id` = (required) - The azure resource ID for the Azure Netapp Files volume being attached to the cluster nodes.
  - `cluster_names`             = (required) - A set of cluster name(s) where this volume should be attached

Example Input:
```hcl
netapp_files_datastores = {
  anf_datastore_cluster1 = {
    netapp_volume_resource_id = module.create_anf_volume.volume_id
    cluster_names             = ["Cluster-1"]
  }
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

Description: A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_secondary_zone"></a> [secondary\_zone](#input\_secondary\_zone)

Description: This value represents the secondary zone in a stretch cluster deployment.

Type: `number`

Default: `null`

### <a name="input_segments"></a> [segments](#input\_segments)

Description: This map object describes the additional segments to configure on the private cloud. It can remain unconfigured or define one or more new network segments. Defaults to unconfigured. If the connected\_gateway value is left undefined, the configuration will default to using the default T1 gateway provisioned as part of the managed service.

- `<map key>` - Provide a key value that will be used as the segment name
  - `display_name`       = (Required) - The display name for the dhcp configuration being created
  - `gateway_address`    = (Required) - The CIDR range to use for the segment
  - `dhcp_ranges`        = (Optional) - One or more ranges of IP addresses or CIDR blocks entered as a list of string
  - `connected_gateway`  = (Optional) - The name of the T1 gateway to connect this segment to.  Defaults to the managed t1 gateway if left unconfigured.

Example Input:
```hcl
segment_1 = {
  display_name    = "segment_1"
  gateway_address = "10.20.0.1/24"
  dhcp_ranges     = ["10.20.0.5-10.20.0.100"]      
}
segment_2 = {
  display_name    = "segment_2"
  gateway_address = "10.30.0.1/24"
  dhcp_ranges     = ["10.30.0.0/24"]
}
```

Type:

```hcl
map(object({
    display_name      = string
    gateway_address   = string
    dhcp_ranges       = optional(list(string), [])
    connected_gateway = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Map of tags to be assigned to the AVS resources

Type: `map(string)`

Default: `null`

### <a name="input_vcenter_identity_sources"></a> [vcenter\_identity\_sources](#input\_vcenter\_identity\_sources)

Description: A map of objects representing a list of 0-2 identity sources for configuring LDAP or LDAPs on the private cloud. The map key will be used as the name value for the identity source.

- `<map key>` - Provide a key value that will be used as the vcenter identity source name
  - `alias`             = (Required) - The domains NETBIOS name
  - `base_group_dn`     = (Required) - The base distinguished name for groups
  - `base_user_dn`      = (Required) - The base distinguished name for users
  - `domain`            = (Required) - The fully qualified domain name for the identity source
  - `group_name`        = (Optional) - The name of the LDAP group that will be added to the cloudadmins role
  - `name`              = (Required) - The name to give the identity source
  - `primary_server`    = (Required) - The URI of the primary server. (Ex: ldaps://server.domain.local:636)
  - `secondary_server`  = (Optional) - The URI of the secondary server. (Ex: ldaps://server.domain.local:636)
  - `ssl`               = (Optional) - Determines if ldap is configured to use ssl. Default to Enabled, valid values are "Enabled" and "Disabled"
  - 'timeout'           = (Optional) - The implementation timeout value.  Defaults to 10 minutes.

Example Input:
```hcl
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

### <a name="input_vcenter_identity_sources_credentials"></a> [vcenter\_identity\_sources\_credentials](#input\_vcenter\_identity\_sources\_credentials)

Description: A map of objects representing the credentials used for the identity source connection. The map key should match the vcenter identity source that uses these values. Separating this to avoid terraform issues with apply on secrets.

- `<map key>` - Provide a key value that will be used as the identity source credentials name. This value should match the identity source key where the credential will be used.
  - `ldap_user`          = (Required) - "The username for the domain user the vcenter will use to query LDAP(s)"
  - `ldap_user_password` = (Required) - "Password to use for the domain user the vcenter will use to query LDAP(s)"

Example Input:
```hcl
{
  test.local = {
    ldap_user               = "user@test.local"
    ldap_user_password      = module.create_dc.ldap_user_password
  }
}
```

Type:

```hcl
map(object({
    ldap_user          = string
    ldap_user_password = string
  }))
```

Default: `{}`

### <a name="input_vcenter_password"></a> [vcenter\_password](#input\_vcenter\_password)

Description: The password value to use for the cloudadmin account password in the local domain in vcenter. If this is left as null a random password will be generated for the deployment

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_credentials"></a> [credentials](#output\_credentials)

Description: This value returns the vcenter and nsxt cloudadmin credential values.

### <a name="output_identity"></a> [identity](#output\_identity)

Description: This output returns the managed identity values if the managed identity has been enabled on the module.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: This output returns the full private cloud resource object properties.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The azure resource if of the private cloud.

### <a name="output_system_assigned_mi_principal_id"></a> [system\_assigned\_mi\_principal\_id](#output\_system\_assigned\_mi\_principal\_id)

Description: The principal id of the system managed identity assigned to the virtual machine

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->