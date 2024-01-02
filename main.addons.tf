#####################################################################################################################################
# Deploy and configure the HCX Addon
#####################################################################################################################################
resource "azapi_resource" "hcx_addon" {
  count = var.hcx_enabled ? 1 : 0

  type = "Microsoft.AVS/privateClouds/addons@2022-05-01"
  #Resource Name must match the addonType
  name      = "HCX"
  parent_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      addonType = "HCX"
      offer     = lower(var.hcx_license_type) == "advanced" ? "VMware MaaS Cloud Provider" : "VMware MaaS Cloud Provider (Enterprise)"
    }
  })

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }

  depends_on = [
    azapi_resource.clusters,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azurerm_role_assignment.this_private_cloud,
    azurerm_vmware_express_route_authorization.this_authorization_key,
    azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}

#adding sleep wait to handle lag in hcx registration for keys
resource "time_sleep" "wait_120_seconds" {
  depends_on = [azapi_resource.hcx_addon]

  create_duration = "60s"
}

#create the hcx key(s) if defined
resource "azapi_resource" "hcx_keys" {
  for_each = toset(var.hcx_key_names)

  type                   = "Microsoft.AVS/privateClouds/hcxEnterpriseSites@2022-05-01"
  name                   = each.key
  parent_id              = azapi_resource.this_private_cloud.id
  response_export_values = ["*"]

  depends_on = [
    time_sleep.wait_120_seconds
  ]

  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }

}

#####################################################################################################################################
# Deploy and configure the SRM Addon
#####################################################################################################################################

resource "azapi_resource" "srm_addon" {
  count = var.srm_enabled ? 1 : 0

  type = "Microsoft.AVS/privateClouds/addons@2022-05-01"
  #Resource Name must match the addonType
  name      = "SRM"
  parent_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      addonType  = "SRM"
      licenseKey = var.srm_license_key
    }
  })

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }

  depends_on = [
    azapi_resource.clusters,
    azapi_resource.hcx_addon
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}


#####################################################################################################################################
# Deploy and configure the VR Addon
#####################################################################################################################################

resource "azapi_resource" "vr_addon" {
  count = var.vr_enabled ? 1 : 0

  type = "Microsoft.AVS/privateClouds/addons@2022-05-01"
  #Resource Name must match the addonType
  name      = "VR"
  parent_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      addonType = "VR"
      vrsCount  = var.vrs_count
    }
  })

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }

  depends_on = [
    azapi_resource.clusters,
    azapi_resource.hcx_addon,
    azapi_resource.srm_addon
  ]

  timeouts {
    create = "4h"
    delete = "4h"
    update = "4h"
  }
}

/* "TODO: determine how to get the Vcenter resource ID"
#####################################################################################################################################
# Deploy and configure the ARC Addon
#####################################################################################################################################
resource "azapi_resource" "arc_addon" {
  count = var.arc_enabled ? 1 : 0

  type = "Microsoft.AVS/privateClouds/addons@2022-05-01"
  #Resource Name must match the addonType
  name      = "Arc"
  parent_id = azapi_resource.this_private_cloud.id
  body = jsonencode({
    properties = {
      addonType   = "Arc"
      vCenter     = 
    }
  })

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }
}
*/