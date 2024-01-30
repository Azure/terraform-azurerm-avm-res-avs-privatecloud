# Select a deployment region for AVS

This module randomizes the selection of a deployment region for the AVS test lab. Given we have limited deployment quota in a few select regions it is necessary to query the quota api to determine where deployments will be successful.  This module recurses the list of all regions where the lab subscription has quota and identifies the number of nodes of quota available for deployments by sku type.  If no quota exists, it will return a region and sku type of "no_quota" which will cause the deployment to error out.

There is logic in each example to cache the deployment selections so that future runs don't change the region and force a complete redeployment.
