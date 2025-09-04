<!-- BEGIN_TF_DOCS -->
# Generate Deployment Region

The test subscription only had limited quota in select regions for testing AVS examples. This module queries the quota API for the allocated test regions to locate one or more regions with available quota and outputs the region and quota details.

```hcl
locals {
  #aggregate all the quota types
  available_quota_by_region = concat(local.available_quota_by_region_av36, local.available_quota_by_region_av36p, local.available_quota_by_region_av64, local.available_quota_by_region_av20, local.available_quota_by_region_av48)
  available_quota_by_region_av20 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av20", hosts = region.output.hostsRemaining.ge } if
  (region.output.hostsRemaining.ge > 0)], [])
  available_quota_by_region_av36 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av36", hosts = region.output.hostsRemaining.he } if
  (region.output.hostsRemaining.he > 0)], [])
  #get the available quota in all the test regions
  available_quota_by_region_av36p = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av36p", hosts = region.output.hostsRemaining.he2 } if
  (region.output.hostsRemaining.he2 > 0)], [])
  available_quota_by_region_av48 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av48", hosts = region.output.hostsRemaining.hf } if
  (region.output.hostsRemaining.hf > 0)], [])
  available_quota_by_region_av64 = try([for region in data.azapi_resource_action.quota :
    { name = split("/", region.resource_id)[6], sku = "av64", hosts = region.output.hostsRemaining.av64 } if
  (region.output.hostsRemaining.av64 > 0)], [])
  #set a default region of no quota for when no quota is available
  region_empty = {
    generation = var.private_cloud_generation
    name       = "no_quota"
    sku-mgmt   = "no_quota"
    sku-sec    = "no_quota"
  }
  test_regions = var.test_regions
  #generate a list of keys to use in the random integer resource
  valid_region_keys = keys(local.valid_regions)
  #merge the valid regions into a single map
  valid_regions = merge(
    local.valid_regions_gen1_dell_only,
    local.valid_regions_gen2_fleet_only,
    local.valid_regions_mixed_dell_fleet
  )
  #get the valid regions for each case
  valid_regions_gen1_dell_only  = var.private_cloud_generation == 1 ? try({ for region, value in local.with_quota_dell : region => { "name" = value.name, "sku-mgmt" = value.sku, "sku-sec" = value.sku, "generation" = 1 } if value.hosts >= (var.management_cluster_quota_required + var.secondary_cluster_quota_required) }, {}) : {}
  valid_regions_gen2_fleet_only = var.private_cloud_generation == 2 ? try({ for region, value in local.with_quota_fleet : region => { "name" = value.name, "sku-mgmt" = value.sku, "sku-sec" = value.sku, "generation" = 2 } if value.hosts >= (var.management_cluster_quota_required + var.secondary_cluster_quota_required) }, {}) : {}
  valid_regions_mixed_dell_fleet = var.private_cloud_generation == 1 ? try({ for region, value in local.with_quota_dell : "${value.name}-${value.sku}-av64" => { "name" = value.name, "sku-mgmt" = value.sku, "sku-sec" = "av64", "generation" = 2 }
  if((value.hosts >= var.management_cluster_quota_required) && try(local.with_quota_fleet["${value.name}-av64"].hosts, 0) >= var.secondary_cluster_quota_required) }, {}) : {}
  #get regions with Dell quota that match the management cluster size
  with_quota_dell  = { for region, quota in local.available_quota_by_region : "${quota.name}-${quota.sku}" => quota if quota.sku != "av64" }
  with_quota_fleet = { for region, quota in local.available_quota_by_region : "${quota.name}-${quota.sku}" => quota if quota.sku == "av64" }
}

data "azurerm_subscription" "current" {}

#query the quota api for each test region
data "azapi_resource_action" "quota" {
  for_each = toset(local.test_regions)

  action                 = "checkQuotaAvailability"
  method                 = "POST"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.AVS/locations/${each.key}"
  type                   = "Microsoft.AVS/locations@2024-09-01"
  response_export_values = ["hostsRemaining"]
}

#generate a random region index if more than one region can satisfy the quota request
resource "random_integer" "region_index" {
  count = length(local.valid_region_keys) > 0 ? 1 : 0

  max = try((length(local.valid_region_keys) - 1), 0)
  min = 0
}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.8)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.115, < 5.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.115, < 5.0)

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

### <a name="input_management_cluster_quota_required"></a> [management\_cluster\_quota\_required](#input\_management\_cluster\_quota\_required)

Description: The total number of host nodes required for the test SDDC deployment.

Type: `number`

Default: `3`

### <a name="input_private_cloud_generation"></a> [private\_cloud\_generation](#input\_private\_cloud\_generation)

Description: The generation of the private cloud. 1 for generation 1 private clouds, 2 for AVS gen 2 private clouds.

Type: `number`

Default: `1`

### <a name="input_secondary_cluster_quota_required"></a> [secondary\_cluster\_quota\_required](#input\_secondary\_cluster\_quota\_required)

Description: The total number of av64 host nodes required for the test SDDC deployment.

Type: `number`

Default: `0`

### <a name="input_test_regions"></a> [test\_regions](#input\_test\_regions)

Description: Supported test regions for the AVS SDDC deployment. This variable allows for specific region overrides for test cases where a specific set of regions are required for that test case.

Type: `list(string)`

Default:

```json
[
  "australiaeast",
  "australiasoutheast",
  "brazilsouth",
  "canadaeast",
  "centralindia",
  "centralus",
  "eastasia",
  "eastus",
  "eastus2",
  "francecentral",
  "germanywestcentral",
  "italynorth",
  "japaneast",
  "japanwest",
  "northcentralus",
  "northeurope",
  "qatarcentral",
  "southafricanorth",
  "southcentralus",
  "southeastasia",
  "swedencentral",
  "switzerlandnorth",
  "switzerlandwest",
  "uaenorth",
  "uksouth",
  "ukwest",
  "westcentralus",
  "westeurope",
  "westus",
  "westus2",
  "westus3"
]
```

## Outputs

The following outputs are exported:

### <a name="output_deployment_region"></a> [deployment\_region](#output\_deployment\_region)

Description: The region map to use for the AVS deployment. Returns no\_quota if all region quota is consumed.

### <a name="output_regions"></a> [regions](#output\_regions)

Description: A map of regions with quota counts.

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