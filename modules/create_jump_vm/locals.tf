locals {
  resource_group_location = var.resource_group_location == null ? var.location : var.resource_group_location
}
