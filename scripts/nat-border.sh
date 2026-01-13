#!/bin/sh
# Script de configuration NAT/Masquerade sur le routeur de bordure AS5

# Activer le forwarding IP
echo 1 > /proc/sys/net/ipv4/ip_forward

# Routes statiques vers les LAN derrière les routeurs internes
ip route replace 120.0.84.0/24 via 120.0.82.10
ip route replace 192.168.5.0/24 via 120.0.83.10
ip route replace 120.0.85.0/24 via 120.0.80.2

# NAT/Masquerade pour le trafic sortant vers Internet
# eth1 est l'interface vers Internet
iptables -t nat -A POSTROUTING -o eth1 -s 120.0.80.0/20 -j MASQUERADE

# Autoriser le forwarding
iptables -A FORWARD -i eth1 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth3 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT

echo "NAT/Masquerade configuré sur AS5-Border"

