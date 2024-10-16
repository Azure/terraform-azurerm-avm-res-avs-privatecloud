variable "total_av64_quota_required" {
  type        = number
  default     = 0
  description = "The total number of av64 host nodes required for the test SDDC deployment."
}

variable "total_quota_required" {
  type        = number
  default     = 3
  description = "The total number of host nodes required for the test SDDC deployment."
}
