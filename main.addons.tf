#####################################################################################################################################
# Deploy and configure the HCX Addon
#####################################################################################################################################
resource "azapi_resource" "hcx_addon" {
  for_each = { for k, v in var.addons : k => v if lower(k) == "hcx" }

  type = "Microsoft.AVS/privateClouds/addons@2023-03-01"
  body = {
    properties = {
      addonType = "HCX"
      offer     = lower(each.value.hcx_license_type) == "advanced" ? "VMware MaaS Cloud Provider" : "VMware MaaS Cloud Provider (Enterprise)"
    }
  }
  #Resource Name must match the addonType
  name      = "HCX"
  parent_id = azapi_resource.this_private_cloud.id

  timeouts {
    create = "4h"
    delete = "4h"
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key
  ]

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }
}

#adding sleep wait to handle lag in hcx registration for keys
resource "time_sleep" "wait_120_seconds" {
  create_duration = "60s"

  depends_on = [azapi_resource.hcx_addon]
}

#create the hcx key(s) if defined
resource "azapi_resource" "hcx_keys" {
  for_each = toset(try(var.addons.hcx.hcx_key_names, []))

  type                   = "Microsoft.AVS/privateClouds/hcxEnterpriseSites@2023-03-01"
  name                   = each.key
  parent_id              = azapi_resource.this_private_cloud.id
  response_export_values = ["*"]

  depends_on = [
    time_sleep.wait_120_seconds,
    azapi_resource.hcx_addon
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
  for_each = { for k, v in var.addons : k => v if lower(k) == "srm" }

  type = "Microsoft.AVS/privateClouds/addons@2023-03-01"
  body = {
    properties = {
      addonType  = "SRM"
      licenseKey = each.value.srm_license_key
    }
  }
  #Resource Name must match the addonType
  name      = "SRM"
  parent_id = azapi_resource.this_private_cloud.id

  timeouts {
    create = "4h"
    delete = "4h"
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys
  ]

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }
}


#####################################################################################################################################
# Deploy and configure the VR Addon
#####################################################################################################################################

resource "azapi_resource" "vr_addon" {
  for_each = { for k, v in var.addons : k => v if lower(k) == "vr" }

  type = "Microsoft.AVS/privateClouds/addons@2023-03-01"
  body = {
    properties = {
      addonType = "VR"
      vrsCount  = each.value.vr_vrs_count
    }
  }
  #Resource Name must match the addonType
  name      = "VR"
  parent_id = azapi_resource.this_private_cloud.id

  timeouts {
    create = "4h"
    delete = "4h"
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    #azapi_update_resource.managed_identity,
    azapi_update_resource.customer_managed_key,
    azapi_resource.hcx_addon,
    azapi_resource.hcx_keys,
    azapi_resource.srm_addon
  ]

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }
}


#####################################################################################################################################
# Deploy and configure the ARC Addon
#####################################################################################################################################
resource "azapi_resource" "arc_addon" {
  for_each = { for k, v in var.addons : k => v if lower(k) == "arc" }

  type = "Microsoft.AVS/privateClouds/addons@2023-03-01"
  body = {
    properties = {
      addonType = "Arc"
      vCenter   = each.value.arc_vcenter
    }
  }
  #Resource Name must match the addonType
  name      = "Arc"
  parent_id = azapi_resource.this_private_cloud.id

  #adding lifecycle block to handle replacement issue with parent_id
  lifecycle {
    ignore_changes = [
      parent_id
    ]
  }
}


