# Default AVS example with Vnet ExpressRoute Gateway

This example demonstrates most of the deployment inputs using a single Azure VMware Solution private cloud with the following features and supporting test resources:

    - A 3-node management cluster and an additional 3-node cluster
    - The HCX Addon enabled with the Enterprise license sku
    - An example HCX site key
    - Diagnostic Settings to send the syslog and metrics to a Log Analytics workspace.
    - Two domain controllers running a simple test active directory domain for use in demonstrating identity provider and dns functionality including
        - Nat Gateway enabled for outbound internet access to download the configuration script from github
        - Bastion enabled for accessing the domain controllers to use them for connecting to vcenter and nsxt for validation and testing
    - A DNS forwarder zone for the test domain
    - An update to the default NSX-T DNS service adding the custom domain forwarder zone
    - An ExpressRoute authorization key
    - An ExpressRoute Gateway connection to an example ExpressRoute gateway in a virtual network.
    - A delete lock on the private cloud resource
    - The system-managed identity enabled
    - An Azure Netapp Files (ANF) Account, Pool, and Volume created in the same availalbility zone for testing external storage 
    - An external storage datastore created using the ANF volume and associated to the management cluster
    - A role assignment assigning Contributor rights on the private cloud resource to the deployment user to demonstrate resource level RBAC
    - A tags block to demonstrate the assignment of resource level tags
    - A Vcenter identity sources block to demonstrate the use of the test domain for ldaps       

The following example code uses several test modules, so be sure to include them and update the deployment regions if copying verbatim.
