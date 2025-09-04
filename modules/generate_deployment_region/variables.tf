variable "management_cluster_quota_required" {
  type        = number
  default     = 3
  description = "The total number of host nodes required for the test SDDC deployment."
}

variable "private_cloud_generation" {
  type        = number
  default     = 1
  description = "The generation of the private cloud. 1 for generation 1 private clouds, 2 for AVS gen 2 private clouds."
}

variable "secondary_cluster_quota_required" {
  type        = number
  default     = 0
  description = "The total number of av64 host nodes required for the test SDDC deployment."
}

variable "test_regions" {
  type = list(string)
  default = ["australiaeast",
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
  description = "Supported test regions for the AVS SDDC deployment. This variable allows for specific region overrides for test cases where a specific set of regions are required for that test case."
}
