resource "azurerm_monitor_diagnostic_setting" "this_private_cloud_diags" {
  for_each = var.diagnostic_settings

  name                           = each.value.name
  target_resource_id             = azapi_resource.this_private_cloud.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }

  depends_on = [
    azapi_resource.this_private_cloud,
    azapi_resource.clusters,
    azurerm_role_assignment.this_private_cloud
  ]
}

