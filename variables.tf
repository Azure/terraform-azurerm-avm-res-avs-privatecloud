############################
# Required Variables
############################
variable "avs_network_cidr" {
  type        = string
  description = "The full /22 or larger network CIDR summary for the private cloud managed components. This range should not intersect with any IP allocations that will be connected or visible to the private cloud."
}

variable "location" {
  type        = string
  description = "The Azure region where this and supporting resources should be deployed.  "
}

variable "name" {
  type        = string
  description = "The name to use when creating the avs sddc private cloud."
  nullable    = false
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "resource_group_resource_id" {
  type        = string
  description = "The resource group Azure Resource ID for the deployment resource group. Used for the AzAPI resource that deploys the private cloud."
}

variable "sku_name" {
  type        = string
  description = "The sku value for the AVS SDDC management cluster nodes. Valid values are av20, av36, av36t, av36pt, av52, av64."
}

variable "addons" {
  type = map(object({
    arc_vcenter      = optional(string)
    hcx_key_names    = optional(list(string), [])
    hcx_license_type = optional(string, "Enterprise")
    srm_license_key  = optional(string)
    vr_vrs_count     = optional(number, 0)
  }))
  default     = {}
  description = <<ADDONS
Map object containing configurations for the different addon types.  Each addon type has associated fields and specific naming requirements.  A full input example is provided below.
  
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
ADDONS
  nullable    = false
}

variable "avs_interconnect_connections" {
  type = map(object({
    linked_private_cloud_resource_id = string
  }))
  default     = {}
  description = <<INTERCONNECT
Map of string objects describing one or more private cloud interconnect connections for private clouds in the same region.  The map key will be used for the connection name.

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
INTERCONNECT
  nullable    = false
}

variable "clusters" {
  type = map(object({
    cluster_node_count = number
    sku_name           = string
  }))
  default     = {}
  description = <<CLUSTERS
This object describes additional clusters in the private cloud in addition to the management cluster. The map key will be used as the cluster name

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
CLUSTERS
  nullable    = false
}

variable "customer_managed_key" {
  type = map(object({
    key_vault_resource_id = optional(string, null)
    key_name              = optional(string, null)
    key_version           = optional(string, null)
  }))
  default     = {}
  description = <<CUSTOMER_MANAGED_KEY
This object defines the customer managed key details to use when encrypting the VSAN datastore. 

- `<map key>` - Provide a custom key value that will be used as the dhcp configuration name
  - `key_vault_resource_id` = (Required) - The full Azure resource ID of the key vault where the encryption key will be sourced from
  - `key_name`              = (Required) - The name for the encryption key
  - `key_version`           = (Optional) - The key version value for the encryption key. 

Example Inputs:
```hcl
{
  key_vault_resource_id = azurerm_key_vault.example.id
  key_name              = azurerm_key_vault_key.example.name
  key_version           = azurerm_key_vault_key.example.version
}
```
CUSTOMER_MANAGED_KEY
  nullable    = false
}

variable "dhcp_configuration" {
  type = map(object({
    display_name           = string
    dhcp_type              = string
    relay_server_addresses = optional(list(string), [])
    server_lease_time      = optional(number, 86400)
    server_address         = optional(string, null)
  }))
  default     = {}
  description = <<DHCP
This map object describes the DHCP configuration to use for the private cloud. It can remain unconfigured or define a RELAY or SERVER based configuration. Defaults to unconfigured. This allows for new segments to define DHCP ranges as part of their definition. Only one DHCP configuration is allowed.

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
DHCP
  nullable    = false
}

variable "diagnostic_settings" {
  type = map(object({
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
  default     = {}
  description = <<DIAGNOSTIC_SETTINGS
This map object is used to define the diagnostic settings on the virtual machine.  This functionality does not implement the diagnostic settings extension, but instead can be used to configure sending the vm metrics to one of the standard targets.

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
DIAGNOSTIC_SETTINGS
  nullable    = false
}

variable "dns_forwarder_zones" {
  type = map(object({
    display_name               = string
    dns_server_ips             = list(string)
    domain_names               = list(string)
    source_ip                  = optional(string, "")
    add_to_default_dns_service = optional(bool, false)
  }))
  default     = {}
  description = <<DNS_FORWARDER_ZONES
Map of string objects describing one or more dns forwarder zones for NSX within the private cloud. Up to 5 additional forwarder zone can be configured. This is primarily useful for identity source configurations or in cases where NSX DHCP is providing DNS configurations.

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
DNS_FORWARDER_ZONES
  nullable    = false
}

variable "elastic_san_datastores" {
  type = map(object({
    cluster_names           = set(string)
    esan_volume_resource_id = string
  }))
  default = {}
}

variable "enable_stretch_cluster" {
  type        = bool
  default     = false
  description = "Set this value to true if deploying an AVS stretch cluster."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "expressroute_connections" {
  type = map(object({
    name                             = string
    expressroute_gateway_resource_id = string
    vwan_hub_connection              = optional(bool, false)
    authorization_key_name           = optional(string, null)
    fast_path_enabled                = optional(bool, false)
    private_link_fast_path_enabled   = optional(bool, false)
    routing_weight                   = optional(number, 0)
    enable_internet_security         = optional(bool, false)
    tags                             = optional(map(string), {})
    network_resource_group_resource_id = optional(string, null)
    network_resource_group_location  = optional(string, null) 
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
  default     = {}
  description = <<EXPRESSROUTE_CONNECTIONS
Map of string objects describing one or more ExpressRoute connections to be configured by the private cloud. The map key will be used for the connection name.

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
EXPRESSROUTE_CONNECTIONS
  nullable    = false
}

variable "extended_network_blocks" {
  type        = list(string)
  default     = []
  description = "If using AV64 sku's in non-management clusters it is required to provide one /23 CIDR block or three /23 CIDR blocks. Provide a list of CIDR strings if planning to use AV64 nodes."
}

variable "external_storage_address_block" {
  type        = string
  default     = null
  description = "If using Elastic SAN or other ISCSI storage, provide an /24 CIDR range as a string for use in connecting the external storage.  Example: 10.10.0.0/24"
}

variable "global_reach_connections" {
  type = map(object({
    authorization_key                     = string
    peer_expressroute_circuit_resource_id = string
  }))
  default     = {}
  description = <<GLOBAL_REACH_CONNECTIONS
Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.

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
GLOBAL_REACH_CONNECTIONS
  nullable    = false
}

variable "internet_enabled" {
  type        = bool
  default     = false
  description = "Configure the internet SNAT option to be on or off. Defaults to off."
}

variable "internet_inbound_public_ips" {
  type = map(object({
    number_of_ip_addresses = number
  }))
  default     = {}
  description = <<PUBLIC_IPS
This map object that describes the public IP configuration. Configure this value in the event you need direct inbound access to the private cloud from the internet. The code uses the map key as the display name for each configuration.

- `<map key>` - Provide a key value that will be used as the public ip configuration name
  - `number_of_ip_addresses` = (required) - The number of IP addresses to assign to this private cloud.

Example Input:
```hcl
public_ip_config = {
  display_name = "public_ip_configuration"
  number_of_ip_addresses = 1
}
```
PUBLIC_IPS
  nullable    = false
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  default     = {}
  description = <<LOCK
"The lock level to apply to this virtual machine and all of it's child resources. The default value is none. Possible values are `None`, `CanNotDelete`, and `ReadOnly`. Set the lock value on child resource values explicitly to override any inherited locks." 

Example Inputs:
```hcl
lock = {
  name = "lock-{resourcename}" # optional
  type = "CanNotDelete" 
}
```
LOCK
  nullable    = false

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

#resource doesn't support user-assigned managed identities.
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled. This is used to configure encryption using customer managed keys.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource. Currently unused by this resource.
  DESCRIPTION
  nullable    = false
}

variable "management_cluster_size" {
  type        = number
  default     = 3
  description = "The number of nodes to include in the management cluster. The minimum value is 3 and the current maximum is 16."
}

variable "netapp_files_datastores" {
  type = map(object({
    netapp_volume_resource_id = string
    cluster_names             = set(string)
  }))
  default     = {}
  description = <<NETAPP_FILES_ATTACHMENTS
This map of objects describes one or more netapp volume attachments.  The map key will be used for the datastore name and should be unique. 

- `<map key>` - Provide a key value that will be used as the netapp files datastore name
  - `netapp_volume_resource_id` = (required) - The azure resource ID for the Azure Netapp Files volume being attached to the cluster nodes.
  - `cluster_names`             = (required) - A set of cluster name(s) where this volume should be attached

Example Input:
```hcl
anf_datastore_cluster1 = {
  netapp_volume_resource_id = azurerm_netapp_volume.test.id
  cluster_names             = ["Cluster-1"]
}
```
NETAPP_FILES_ATTACHMENTS
  nullable    = false
}

variable "nsxt_password" {
  type        = string
  default     = null
  description = "The password value to use for the cloudadmin account password in the local domain in nsxt. If this is left as null a random password will be generated for the deployment"
  sensitive   = true
}

variable "primary_zone" {
  type        = number
  default     = null
  description = "This value represents the zone for deployment in a standard deployment or the primary zone in a stretch cluster deployment. Defaults to null to let Azure select the zone"
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, true)
    delegated_managed_identity_resource_id = optional(string)
    }
  ))
  default     = {}
  description = <<ROLE_ASSIGNMENTS
A list of role definitions and scopes to be assigned as part of this resources implementation.  

- `<map key>` - Provide a key value that will be used as the role assignments name
  - `principal_id`                               = (optional) - The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.
  - `role_definition_id_or_name`                 = (Optional) - The Scoped-ID of the Role Definition or the built-in role name. Changing this forces a new resource to be created. Conflicts with role_definition_name 
  - `condition`                                  = (Optional) - The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.
  - `condition_version`                          = (Optional) - The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.
  - `description`                                = (Optional) - The description for this Role Assignment. Changing this forces a new resource to be created.
  - `skip_service_principal_aad_check`           = (Optional) - If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. Defaults to true.
  - `delegated_managed_identity_resource_id`     = (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.  

Example Inputs:
```hcl
role_assignments = {
  role_assignment_1 = {
    role_definition_id_or_name                 = "Contributor"
    principal_id                               = data.azuread_client_config.current.object_id
    description                                = "Example for assigning a role to an existing principal for the Private Cloud scope"        
  }
}
```
ROLE_ASSIGNMENTS
  nullable    = false
}

variable "secondary_zone" {
  type        = number
  default     = null
  description = "This value represents the secondary zone in a stretch cluster deployment."
}

variable "segments" {
  type = map(object({
    display_name      = string
    gateway_address   = string
    dhcp_ranges       = optional(list(string), [])
    connected_gateway = optional(string, null)
  }))
  default     = {}
  description = <<SEGMENTS
This map object describes the additional segments to configure on the private cloud. It can remain unconfigured or define one or more new network segments. Defaults to unconfigured. If the connected_gateway value is left undefined, the configuration will default to using the default T1 gateway provisioned as part of the managed service.

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
SEGMENTS
  nullable    = false
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Map of tags to be assigned to this resource"
}

variable "vcenter_identity_sources" {
  type = map(object({
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
  default     = {}
  description = <<VCENTER_IDENTITY_SOURCES
A map of objects representing a list of 0-2 identity sources for configuring LDAP or LDAPs on the private cloud. The map key will be used as the name value for the identity source.

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
VCENTER_IDENTITY_SOURCES
  nullable    = false
}

variable "vcenter_identity_sources_credentials" {
  type = map(object({
    ldap_user          = string
    ldap_user_password = string
  }))
  default     = {}
  description = <<VCENTER_IDENTITY_SOURCES_CREDENTIALS
A map of objects representing the credentials used for the identity source connection. The map key should match the vcenter identity source that uses these values. Separating this to avoid terraform issues with apply on secrets.

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
VCENTER_IDENTITY_SOURCES_CREDENTIALS
  nullable    = false
  sensitive   = true
}

variable "vcenter_password" {
  type        = string
  default     = null
  description = "The password value to use for the cloudadmin account password in the local domain in vcenter. If this is left as null a random password will be generated for the deployment"
  sensitive   = true
}
