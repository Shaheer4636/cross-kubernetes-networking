# Cross-Region Kubernetes Networking with OVS, OVN, and BGP (FRR)

## Overview

This experimental configuration sets up a **multi-region Kubernetes communication topology** across AWS using open networking technologies. Each region hosts an isolated Kubernetes control node (via **K3s**) connected over **BGP (FRR)**. The underlying fabric is orchestrated using **Open vSwitch (OVS)** and **Open Virtual Network (OVN)**.

This project’s primary focus is not container orchestration alone, but rather the **convergence of virtual networking and dynamic routing** in cloud-hosted environments — aligned with the kind of modular, federated systems deployed in research computing and HPC platforms. This serves as a research&development to showcase exactly how we can achieve the results and later apply in dev, and production. 

---

## Objectives

* **Provision dual VPCs** across `us-east-1` and `us-west-2`, each operating independently yet designed for intercommunication.
* Use **Terraform** to declaratively construct the environment with consistency and reproducibility.
* **Install and configure FRR** to simulate inter-datacenter routing using **BGP sessions**.
* **Use OVN and OVS** to manage virtual switching and routing for Kubernetes pods within and across VPCs.
* Verify **pod-level connectivity** across regions using dynamically propagated routes.
* Provide **logical diagrams** representing both cloud-level topology and intra-VM system layering.

---

## AWS-Level Topology

![AWS Network Architecture](./diagrams/networking-aws-arch.drawio%20(1).png)

This figure describes the full infrastructure deployment pipeline. It is composed of two isolated VPCs, each hosting a single Ubuntu-based EC2 instance configured as a Kubernetes control node. Key characteristics:

* **VPC CIDRs**: `10.0.0.0/16` (east), `10.1.0.0/16` (west)
* **Subnets**: Single public subnet per region for simplicity (`10.0.1.0/24`, `10.1.1.0/24`)
* **Security Groups**: Permit essential ports for:

  * SSH (`22`)
  * FRR BGP (`179`)
  * OVN southbound (`6641`) and northbound (`6642`) databases
* **EC2 Instances**:

  * Ubuntu 22.04 LTS
  * Serve as both Kubernetes (k38s) control planes and BGP peers
* **Automation Stack (iac)**:

  * Terraform provisions all components, eliminating manual AWS console interactions.
  * Configuration scripts are triggered on instance boot to set up networking stack.

---

## Internal VM Architecture

![Inside VM Architecture](./inside-vm-ff.drawio.png)

This figure outlines the internal network subsystem stack of a single node. The architecture draws on core Linux networking primitives layered with userland routing and orchestration components.

### Layered Stack (Bottom to Top)

1. **Ubuntu 22.04 LTS** – OS layer; stable base for reproducible builds.
2. **ON5S (Linux kernel networking)** – Handles interfaces, routing tables, and IP stack.
3. **Open vSwitch (OVS)** – L2/L3 programmable virtual switch; acts as the dataplane for OVN.
4. **TCP** – Transport layer used for OVN and FRR communications.
5. **Control Daemons**:

   * **OVN** – Manages logical switches and routers.
   * **FRR (BGP)** – Establishes route exchange between remote nodes.
   * **K3s** – Lightweight Kubernetes, used to run container workloads.
6. **Nginx Pod** – A simple Kubernetes pod used to validate cross-VPC reachability.

### Installation Notes

All userland components (OVS, OVN, FRR, K3s) are installed via `.deb` packages or compiled from source as appropriate. Inter-process communication (e.g., between OVN and OVS) occurs via Unix domain sockets.

---

## Methodology

1. **Terraform** provisions both networks, security groups, EC2s, and key-pairs.
2. On each EC2 instance:

   * `post-install.sh` installs required components and seeds configuration files.
   * `frr_bgp_autosetup.sh` configures BGP neighbors by inspecting local routing info.
3. K3s is bootstrapped with Flannel CNI.
4. A sample nginx pod is deployed to verify pod-to-pod reachability.
5. Route propagation is validated using:

   ```bash
   vtysh -c "show ip bgp summary"
   ```

---

## Results

* BGP peering is successfully established between nodes using FRR.
* Routes to remote pod CIDRs are dynamically exchanged and injected into local routing tables.
* Nginx pods in one region can be reached via their CNI subnet from the other region.
* The system demonstrates viability of cloud-native cross-regional mesh networking using open protocols.

---

## Relevance to Scientific Computing

This architecture mimics the **hybrid compute environment** found in grid computing or data-intensive research facilities (e.g., LHC computing grid), where **distributed cluster domains** must communicate securely and efficiently. BGP serves as a robust mechanism for route control, while OVN + OVS abstract the underlying infrastructure to offer software-defined isolation and segmentation.

---

## Files & Structure

```bash
.
├── terraform/
│   └── main.tf                 # AWS infrastructure definition
├── frr_bgp_autosetup.sh        # Peer discovery + dynamic FRR config
├── post-install.sh             # System provisioning (OVS, OVN, K3s, FRR)
├── networking-aws-arch.drawio.png
├── inside-vm-ff.drawio.png
└── README.md
```

---

## Future Work

* Integrate monitoring (e.g., Prometheus exporters for FRR and OVN).
* Deploy real-world multi-service applications across both clusters.
* Simulate failure scenarios and observe BGP route convergence.

## Authors & Credits

Demonstrated by \Muhammad Shaheer with intention to demonstrate **poc for cross region k8s pods communication** 
