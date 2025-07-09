#!/bin/bash

set -e

echo "[*] Updating system..."
apt update -y
apt upgrade -y

echo "[*] Installing Open vSwitch and OVN components..."
apt install -y openvswitch-switch ovn-common ovn-host ovn-central

echo "[*] Enabling and starting OVS and OVN services..."
systemctl enable openvswitch-switch
systemctl start openvswitch-switch

systemctl enable ovn-controller
systemctl start ovn-controller

systemctl enable ovn-northd
systemctl start ovn-northd

echo "[*] Setting OVN NB and SB DB sockets..."
export OVN_NB_DB=unix:/var/run/ovn/ovnnb_db.sock
export OVN_SB_DB=unix:/var/run/ovn/ovnsb_db.sock

echo "[*] Creating OVN logical switch and router..."
ovn-nbctl lr-add router1 || true
ovn-nbctl ls-add switch1 || true
ovn-nbctl lrp-add router1 rp-router1 00:00:00:00:ff:01 192.168.100.1/24 || true
ovn-nbctl lsp-add switch1 swp1 || true
ovn-nbctl lsp-set-type swp1 router
ovn-nbctl lsp-set-addresses swp1 router
ovn-nbctl lsp-set-options swp1 router-port=rp-router1

echo "[*] Installing FRR for BGP..."
apt install -y frr frr-pythontools

echo "[*] Enabling BGP in FRR..."
sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
systemctl enable frr
systemctl restart frr

echo "[*] Installing K3s without Flannel..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy" sh -

echo "[*] Installing or ensuring SSM agent is running..."
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

echo "[*] Provisioning complete. OVN, OVS, FRR, K3s, and SSM Agent are installed."
echo "Next step: configure /etc/frr/frr.conf for BGP peering."
