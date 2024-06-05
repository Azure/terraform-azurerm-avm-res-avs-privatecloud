<!-- BEGIN_TF_DOCS -->
# Generate Deployment Region

The test subscription only had limited quota in select regions for testing AVS examples. This module queries the quota API for the allocated test regions to locate one or more regions with available quota and outputs the region and quota details.

```hcl
locals {
  region = {
    name = "no_quota"
    sku  = "no_quota"
  }
  test_regions     = ["southafricanorth", "eastasia", "canadacentral", "germanywestcentral"]
  with_quota       = concat(local.with_quota_av36, local.with_quota_av36p)
  with_quota_av36  = try([for region in jsondecode(data.azapi_resource_action.quota) : { name = split("/", region.resource_id)[6], sku = "av36" } if region.output.hostsRemaining.he >= var.total_quota_required], [])
  with_quota_av36p = try([for region in jsondecode(data.azapi_resource_action.quota) : { name = split("/", region.resource_id)[6], sku = "av36p" } if region.output.hostsRemaining.he2 >= var.total_quota_required], [])
}

data "azurerm_subscription" "current" {}

#query the quota api for each test region
data "azapi_resource_action" "quota" {
  for_each = toset(local.test_regions)

  type                   = "Microsoft.AVS/locations@2023-03-01"
  action                 = "checkQuotaAvailability"
  method                 = "POST"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.AVS/locations/${each.key}"
  response_export_values = ["hostsRemaining"]
}

#generate a random region index if more than one region can satisfy the quota request
resource "random_integer" "region_index" {
  count = try((length(local.with_quota) > 0), false) ? 1 : 0 #fails if we don't have quota

  max = try((length(local.with_quota) - 1), 0)
  min = 0
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13, != 1.13.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.105)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.105)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azapi_resource_action.quota](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_total_quota_required"></a> [total\_quota\_required](#input\_total\_quota\_required)

Description: The total number of host nodes required for the test SDDC deployment.

Type: `number`

Default: `3`

## Outputs

The following outputs are exported:

### <a name="output_deployment_region"></a> [deployment\_region](#output\_deployment\_region)

Description: The region map to use for the AVS deployment. Returns no\_quota if all region quota is consumed.

### <a name="output_regions_with_quota"></a> [regions\_with\_quota](#output\_regions\_with\_quota)

Description: A map of regions that meet the quota requirement.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The region map to use for the AVS deployment. Returns no\_quota if all region quota is consumed. Duplicating the deployment region output to comply with the AVM spec.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: A map of regions that meet the quota requirement. Duplicating the regions with quota output to comply with the AVM spec.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->