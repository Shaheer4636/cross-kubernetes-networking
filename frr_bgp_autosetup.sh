#!/bin/bash

set -e

echo "[*] Installing dependencies..."
sudo apt update -y
sudo apt install -y frr frr-pythontools net-tools

echo "[*] Getting local IP address for ens5..."
LOCAL_IP=$(ip -4 addr show dev ens5 | grep inet | awk '{print $2}' | cut -d/ -f1)
echo "  -> Found IP: $LOCAL_IP"

echo "[*] Updating /etc/frr/daemons to enable zebra and bgpd..."
sudo sed -i 's/^zebra=no/zebra=yes/' /etc/frr/daemons
sudo sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons

echo "[*] Restarting FRR service..."
sudo systemctl restart frr
sudo systemctl enable frr

echo "[*] Generating frr.conf with peer config..."

# Determine peer IP and ASN from the local IP
if [[ "$LOCAL_IP" == 10.0.* ]]; then
    PEER_IP="10.1.1.40"
    LOCAL_AS=65001
    PEER_AS=65002
    NETWORK="10.0.1.0/24"
    ROUTER_ID="10.0.1.34"
else
    PEER_IP="10.0.1.34"
    LOCAL_AS=65002
    PEER_AS=65001
    NETWORK="10.1.1.0/24"
    ROUTER_ID="10.1.1.40"
fi

sudo bash -c "cat > /etc/frr/frr.conf" <<EOF
frr version 8.4
frr defaults traditional
hostname frr
log syslog
service integrated-vtysh-config
!
interface ens5
 ip address $LOCAL_IP/24
!
router bgp $LOCAL_AS
 bgp router-id $ROUTER_ID
 neighbor $PEER_IP remote-as $PEER_AS
 !
 address-family ipv4 unicast
  network $NETWORK
  neighbor $PEER_IP activate
 exit-address-family
!
line vty
!
EOF

echo "[*] Restarting FRR to apply configuration..."
sudo systemctl restart frr

echo "[*] Verifying BGP status..."
sudo vtysh -c "show ip bgp summary"
