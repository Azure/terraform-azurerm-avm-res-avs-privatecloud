
#configure the resource locks
resource "azurerm_management_lock" "this_private_cloud" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azapi_resource.this_private_cloud.id
  lock_level = var.lock.kind

  depends_on = [ #deploy all sub-resources before adding locks in case someone configures a read-only lock
    azapi_resource.hcx_addon,
    azapi_resource.srm_addon,
    azapi_resource.vr_addon,
    azapi_resource.hcx_keys,
    azapi_update_resource.managed_identity,
    azapi_resource.clusters,
    azurerm_vmware_express_route_authorization.this_authorization_key,
    azurerm_monitor_diagnostic_setting.this_private_cloud_diags,
    azurerm_role_assignment.this_private_cloud,
    azapi_update_resource.customer_managed_key,
    azapi_resource.this_private_cloud
  ]
}
