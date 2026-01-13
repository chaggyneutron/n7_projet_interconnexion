#!/bin/sh
# Script d'initialisation de la Box Particulier 5 (NAT)

# Activer le forwarding IP
echo 1 > /proc/sys/net/ipv4/ip_forward

# Identifier les interfaces WAN/LAN dynamiquement
WAN_IF=$(ip -o -4 addr show | grep '120.0.83.10' | awk '{print $2}')
LAN_IF=$(ip -o -4 addr show | grep '192.168.5.1' | awk '{print $2}')
WAN_IF=${WAN_IF:-eth0}
LAN_IF=${LAN_IF:-eth1}

# Route par le routeur de bordure AS5
ip route replace default via 120.0.83.1 dev "$WAN_IF"

# NAT/Masquerade pour le LAN domestique
iptables -t nat -A POSTROUTING -o "$WAN_IF" -s 192.168.5.0/24 -j MASQUERADE

# Autoriser le forwarding
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "$LAN_IF" -o "$WAN_IF" -j ACCEPT

# Autoriser le trafic depuis le LAN domestique
iptables -A INPUT -s 192.168.5.0/24 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Politique par défaut
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Box Particulier 5 initialisée avec NAT"

