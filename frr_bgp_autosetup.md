
# FRR BGP Auto-Configuration Script

## Overview

This script automates the setup of [Free Range Routing (FRR)](https://frrouting.org/) to enable BGP-based dynamic route advertisement between geographically distributed Kubernetes clusters. It is designed as part of a broader scientific simulation involving cross-region VPCs and SDN-aware Kubernetes networking. This configuration enables inter-region pod communication through BGP route exchange over the underlying infrastructure.

## Key Capabilities

- **Automated peer detection** based on instance subnet and region
- **Dynamic BGP configuration** with proper ASN mapping and neighbor setup
- **Daemon activation and system restart**, ensuring reproducibility and correctness
- **Stateless and region-agnostic**, making it compatible with both east and west instances

## What It Does

The script:

1. Installs required packages: `frr`, `frr-pythontools`, `net-tools`
2. Extracts the local IP address from the `ens5` interface
3. Determines the BGP peer’s IP and ASN based on region-aware IP logic
4. Enables necessary FRR daemons (`zebra` and `bgpd`) via `/etc/frr/daemons`
5. Dynamically generates a complete `/etc/frr/frr.conf` file
6. Restarts the FRR service to apply configuration
7. Displays current BGP peering status using `vtysh`

## IP and ASN Logic

The script automatically chooses the correct configuration based on the detected local IP:

- If `LOCAL_IP` starts with `10.0.*` (East node):
  - `LOCAL_AS=65001`, `PEER_AS=65002`
  - `NETWORK=10.0.1.0/24`, `PEER_IP=10.1.1.40`
- If `LOCAL_IP` starts with `10.1.*` (West node):
  - `LOCAL_AS=65002`, `PEER_AS=65001`
  - `NETWORK=10.1.1.0/24`, `PEER_IP=10.0.1.34`

## Usage

```bash
chmod +x frr_bgp_autosetup.sh
sudo ./frr_bgp_autosetup.sh
````

Upon execution, you should observe:

* BGP daemons enabled and restarted
* Proper config file written to `/etc/frr/frr.conf`
* Final output from `show ip bgp summary` showing the peering state

## Prerequisites

* Ubuntu 22.04 LTS with root permissions
* Pre-established VPC peering between AWS regions
* Open TCP port 179 for BGP
* Connectivity between 10.0.1.34 and 10.1.1.40

## Reference

The logic follows standard BGP practices as documented in BGP Explained](https://www.cloudflare.com/learning/security/glossary/what-is-bgp/) and [FRR Official Docs](https://docs.frrouting.org/en/latest/).

