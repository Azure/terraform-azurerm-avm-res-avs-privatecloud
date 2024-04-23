# Default AVS example with VWAN ExpressRoute Gateway

This example demonstrates a deployment with a single Azure VMware Solution private cloud with the following features:

    - A single 3-node management cluster
    - The HCX Addon enabled with the Enterprise license sku
    - An example HCX site key
    - An ExpressRoute authorization key
    - An ExpressRoute Gateway connection to an example ExpressRoute gateway in a VWAN hub.
    - Diagnostic Settings to send the syslog and metrics to a Log Analytics workspace.
    - A server 2022 jump virtual machine for vcenter and NSX-t console access with:
        - Nat Gateway enabled for outbound internet access
        - Bastion enabled for accessing the Jump Box GUI
