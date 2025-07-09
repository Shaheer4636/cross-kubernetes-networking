
#  INstalling Script for OVN, OVS, FRR, and K3s

## Purpose

This script automates the provisioning of an Ubuntu-based virtual machine to set up a fully functional SDN- and BGP-aware Kubernetes environment. It is designed to bootstrap the essential network virtualization and routing components required for building a cross-region Kubernetes communication proof-of-concept.



## Components Installed

| Component | Description |
|----------|-------------|
| **Open vSwitch (OVS)** | Software switch used for creating virtualized networking on VMs. |
| **Open Virtual Network (OVN)** | SDN controller that works with OVS for creating logical networks. |
| **Free Range Routing (FRR)** | Dynamic routing suite supporting BGP for route propagation. |
| **K3s** | Lightweight Kubernetes distribution deployed without flannel to allow OVN CNI integration. |
| **SSM Agent** | AWS Systems Manager agent for secure remote access and automation. |

---

## What This Script Does

1. **System Update**  
   Performs `apt update` and `upgrade` to ensure the OS is up-to-date.

2. **Installs Core Networking Stack**  
   Installs Open vSwitch, OVN components (`ovn-host`, `ovn-central`), and ensures OVS/OVN services are started.

3. **Initial OVN Logical Topology**  
   Creates an OVN logical router and switch, and wires them using logical ports to establish Layer 2–3 topology inside the overlay network.

4. **Installs and Enables FRR**  
   Installs FRR and enables `bgpd` for BGP support. The FRR daemon will later handle route advertisements across Kubernetes regions.

5. **Deploys K3s Kubernetes**  
   Installs K3s with flannel explicitly disabled, preparing the node to use OVN as the primary CNI backend.

6. **Enables SSM Agent**  
   Installs and starts the AWS SSM agent for remote control or automation in environments like AWS EC2.


* Note this script assumes you are using Ubuntu 22.04+


## Post-Provisioning Steps

After running the script:

* Edit `/etc/frr/frr.conf` manually or using automation tools to configure BGP neighbors.
* Validate services:

  ```bash
  systemctl status openvswitch-switch
  systemctl status ovn-controller
  systemctl status ovn-northd
  systemctl status frr
  systemctl status k3s
  ```
* Validate OVN topology:

  ```bash
  ovn-nbctl show
  ```

