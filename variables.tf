variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "name" {
  type        = string
  description = "The name to use when creating the avs sddc private cloud."
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where this and supporting resources should be deployed.  Defaults to the Resource Groups location if undefined."
  default     = null
}

variable "sku_name" {
  type        = string
  description = "The sku value for the AVS SDDC management cluster nodes. Valid values are av20, av36, av36t, av36pt, av52, av64."
}

variable "avs_network_cidr" {
  type        = string
  description = "The full /22 or larger network CIDR summary for the private cloud managed components. This range should not intersect with any IP allocations that will be connected or visible to the private cloud."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Map of tags to be assigned to this resource"
}

variable "internet_enabled" {
  type        = bool
  description = "Configure the internet SNAT option to be on or off. Defaults to off."
  default     = false
}

variable "management_cluster_size" {
  type        = number
  description = "The number of nodes to include in the management cluster. The minimum value is 3 and the current maximum is 16."
  default     = 3
}

variable "vcenter_password" {
  type        = string
  description = "The password value to use for the cloudadmin account password in the local domain in vcenter. If this is left as null a random password will be generated for the deployment"
  default     = null
  sensitive   = true
}

variable "nsxt_password" {
  type        = string
  description = "The password value to use for the cloudadmin account password in the local domain in nsxt. If this is left as null a random password will be generated for the deployment"
  default     = null
  sensitive   = true
}

variable "hcx_enabled" {
  type        = bool
  description = "Enable the HCX addon toggle value"
  default     = false
}

variable "hcx_license_type" {
  type        = string
  description = "Describes which HCX license option to use.  Valid values are Advanced or Enterprise."
  default     = "Advanced"
}

variable "hcx_key_names" {
  type        = list(string)
  description = "list of key names to use when generating hcx site activation keys. Requires HCX add_on to be enabled."
  default     = []
}

variable "srm_enabled" {
  type        = bool
  description = "Enable the SRM addon toggle value"
  default     = false
}

variable "srm_license_key" {
  type        = string
  description = "The license key to use for the SRM installation"
  default     = null
}

variable "vr_enabled" {
  type        = bool
  description = "Enable the Vsphere Replication (VR) addon toggle value"
  default     = false
}

variable "vrs_count" {
  type        = number
  description = "The total number of vsphere replication servers to deploy"
  default     = null
}

variable "arc_enabled" {
  type        = bool
  description = "Enable the ARC addon toggle value"
  default     = false
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
  default = {}

  description = <<VIRTUAL_MACHINE_ROLE_ASSIGNMENTS
  A list of role definitions and scopes to be assigned as part of this resources implementation.  Two forms are supported. Assignments against this virtual machine resource scope and assignments to external resource scopes using the system managed identity.
  list(object({
    principal_id                               = (optional) - The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.
    role_definition_id_or_name                 = (Optional) - The Scoped-ID of the Role Definition or the built-in role name. Changing this forces a new resource to be created. Conflicts with role_definition_name 
    condition                                  = (Optional) - The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.
    condition_version                          = (Optional) - The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.
    description                                = (Optional) - The description for this Role Assignment. Changing this forces a new resource to be created.
    skip_service_principal_aad_check           = (Optional) - If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. Defaults to true.
    delegated_managed_identity_resource_id     = (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.  
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
  VIRTUAL_MACHINE_ROLE_ASSIGNMENTS
}

#Diagnostic Settings
variable "diagnostic_settings" {
  type = map(object({
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
  default     = {}
  nullable    = false
  description = <<DIAGNOSTIC_SETTINGS
  This map object is used to define the diagnostic settings on the virtual machine.  This functionality does not implement the diagnostic settings extension, but instead can be used to configure sending the vm metrics to one of the standard targets.
  map(object({
    name                                     = (required) - Name to use for the Diagnostic setting configuration.  Changing this creates a new resource
    log_categories_and_groups                = (Optional) - List of strings used to define log categories and groups. Currently not valid for the VM resource
    metric_categories                        = (Optional) - List of strings used to define metric categories. Currently only AllMetrics is valid
    log_analytics_destination_type           = (Optional) - Valid values are null, AzureDiagnostics, and Dedicated.  Defaults to null
    workspace_resource_id                    = (Optional) - The Log Analytics Workspace Azure Resource ID when sending logs or metrics to a Log Analytics Workspace
    storage_account_resource_id              = (Optional) - The Storage Account Azure Resource ID when sending logs or metrics to a Storage Account
    event_hub_authorization_rule_resource_id = (Optional) - The Event Hub Namespace Authorization Rule Resource ID when sending logs or metrics to an Event Hub Namespace
    event_hub_name                           = (Optional) - The Event Hub name when sending logs or metrics to an Event Hub
    marketplace_partner_resource_id          = (Optional) - The marketplace partner solution Azure Resource ID when sending logs or metrics to a partner integration
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
  DIAGNOSTIC_SETTINGS
}

#resource doesn't support user-assigned managed identities.
variable "managed_identities" {
  type = object({
    system_assigned = optional(bool, false)
  })
  default = {}
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  description = <<LOCK
    "The lock level to apply to this virtual machine and all of it's child resources. The default value is none. Possible values are `None`, `CanNotDelete`, and `ReadOnly`. Set the lock value on child resource values explicitly to override any inherited locks." 

    Example Inputs:
    ```terraform
    lock = {
      name = "lock-{resourcename}" # optional
      type = "CanNotDelete" 
    }
    ```
    LOCK
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
  })
  default     = null
  description = <<CUSTOMER_MANAGED_KEY
    This object defines the customer managed key details to use when encrypting the VSAN datastore. 

    Example Inputs:
    ```terraform
      {
        key_vault_resource_id = azurerm_key_vault.example.id
        key_name              = azurerm_key_vault_key.example.name
        key_version           = azurerm_key_vault_key.example.version
      }
    ```
    CUSTOMER_MANAGED_KEY
}

variable "clusters" {
  type = map(object({
    cluster_node_count = number
    sku_name           = string
  }))
  default     = {}
  description = <<CLUSTERS
    This object describes additional clusters in the private cloud in addition to the management cluster. The map key will be used as the cluster name
    map(object({
      cluster_node_count = (required) - Integer number of nodes to include in this cluster between 3 and 16
      sku_name           = (required) - String for the sku type to use for the cluster nodes. Changing this forces a new cluster to be created
      
    Example Input:
    ```terraform
       cluster1 = {
        cluster_node_count = 3
        sku_name           = "av36p"
       }
    ```
  CLUSTERS
}

variable "expressroute_auth_keys" {
  type        = set(string)
  default     = []
  description = "This set of strings defines one or more names to creating new expressroute authorization keys for the private cloud"
}

variable "primary_zone" {
  type        = number
  default     = null
  description = "This value represents the zone for deployment in a standard deployment or the primary zone in a stretch cluster deployment. Defaults to null to let Azure select the zone"
}

variable "secondary_zone" {
  type        = number
  default     = null
  description = "This value represents the secondary zone in a stretch cluster deployment."
}

variable "enable_stretch_cluster" {
  type        = bool
  default     = false
  description = "Set this value to true if deploying an AVS stretch cluster."
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

    map(object({
      alias                   = (Required) - The domains NETBIOS name
      base_group_dn           = (Required) - The base distinguished name for groups
      base_user_dn            = (Required) - The base distinguished name for users
      domain                  = (Required) - The fully qualified domain name for the identity source
      group_name              = (Optional) - The name of the LDAP group that will be added to the cloudadmins role
      name                    = (Required) - The name to give the identity source
      password                = (Required) - Password to use for the domain user the vcenter will use to query LDAP(s)
      primary_server          = (Required) - The URI of the primary server. (Ex: ldaps://server.domain.local:636)
      secondary_server        = (Optional) - The URI of the secondary server. (Ex: ldaps://server.domain.local:636)
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
  VCENTER_IDENTITY_SOURCES
}

variable "ldap_user" {
  type        = string
  description = "The username for the domain user the vcenter will use to query LDAP(s)"
  default     = null
}

variable "ldap_user_password" {
  type        = string
  description = "Password to use for the domain user the vcenter will use to query LDAP(s)"
  sensitive   = true
  default     = null
}

variable "global_reach_connections" {
  type = map(object({
    authorization_key                     = string
    peer_expressroute_circuit_resource_id = string
  }))
  default     = {}
  description = <<GLOBAL_REACH_CONNECTIONS
    Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.
    map(object({
      authorization_key                     = (Required) - The authorization key from the peer expressroute 
      peer_expressroute_circuit_resource_id = (Optional) - Identifier of the ExpressRoute Circuit to peer within the global reach connection
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

  GLOBAL_REACH_CONNECTIONS
}

variable "expressroute_connections" {
  type = map(object({
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
  default     = {}
  description = <<GLOBAL_REACH_CONNECTIONS
    Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.
    map(object({
    vwan_hub_connection                                  = (Optional) - Set this to true if making a connection to a VWAN hub.  Leave as false if connecting to an ExpressRoute gateway in a virtual network hub.
    expressroute_gateway_resource_id                     = (Required) - The Azure Resource ID for the ExpressRoute gateway where the connection will be made.
    authorization_key_name                               = (Optional) - The authorization key name that should be used from the auth key map. If no key is provided a name will be generated from the map key.
    fast_path_enabled                                    = (Optional) - Should fast path gateway bypass be enabled. There are sku and cost considerations to be aware of when enabling fast path. Defaults to false
    routing_weight                                       = (Optional) - The routing weight value to use for this connection.  Defaults to 0.
    enable_internet_security                             = (Optional) - Set this to true if connecting to a secure VWAN hub and you want the hub NVA to publish a default route to AVS.
    routing                                              = optional(map(object({
      associated_route_table_resource_id = (Optional) - The Azure Resource ID of the Virtual Hub Route Table associated with this Express Route Connection.
      inbound_route_map_resource_id      = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for inbound learned routes
      outbound_route_map_resource_id     = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for outbound advertised routes
      propagated_route_table = object({ 
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

  GLOBAL_REACH_CONNECTIONS
}

variable "dns_forwarder_zones" {
  type = map(object({
    display_name               = string
    dns_server_ips             = list(string)
    domain_names               = list(string)
    revision                   = optional(number, 0)
    source_ip                  = optional(string, "")
    add_to_default_dns_service = optional(bool, false)
  }))
  default     = {}
  description = <<DNS_FORWARDER_ZONES
    Map of string objects describing one or more dns forwarder zones for NSX within the private cloud. Up to 5 additional forwarder zone can be configured. 
    This is primarily useful for identity source configurations or in cases where NSX DHCP is providing DNS configurations.
    map(object({
    display_name   = (Required) - The display name for the new forwarder zone being created.  Commonly this aligns with the domain name.
    dns_server_ips = (Required) - A list of up to 3 IP addresses where zone traffic will be forwarded.
    domain_names   = (Required) - A list of domain names that will be forwarded as part of this zone.
    revision       = (Optional) - NSX Revision number.  Defaults to 0
    source_ip      = (Optional) - Source IP of the DNS zone.  Defaults to an empty string.  
  }))

  Example Input:
    ```terraform
    {
      exr_region_1 = {
        expressroute_gateway_resource_id                     = "<expressRoute Gateway Resource ID>"
        peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
      }
    }

  DNS_FORWARDER_ZONES

}

variable "netapp_files_datastores" {
  type = map(object({
    netapp_volume_resource_id = string
    cluster_names             = set(string)
  }))
  default     = {}
  description = <<NETAPP_FILES_ATTACHMENTS
    This map of objects describes one or more netapp volume attachments.  The map key will be used for the datastore name and should be unique. 

    map(object({
      netapp_volume_resource_id = (required) - The azure resource ID for the Azure Netapp Files volume being attached to the cluster nodes.
      cluster_names             = (required) - A set of cluster name(s) where this volume should be attached
    }))

    Example Input:
    ```terraform
      anf_datastore_cluster1 = {
        netapp_volume_resource_id = azurerm_netapp_volume.test.id
        cluster_names             = ["Cluster-1"]
      }
    ```
  NETAPP_FILES_ATTACHMENTS
}
