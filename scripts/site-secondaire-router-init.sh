#!/bin/sh
# Script d'initialisation du routeur site secondaire (mise à jour - VPN Only)

# Activer le forwarding IP
echo 1 > /proc/sys/net/ipv4/ip_forward

# Route vers Internet via 10.0.1.1
ip route replace default via 10.0.1.1 dev eth0

# Démarrage OpenVPN client si présent
if [ -f /etc/openvpn/client-entreprise.conf ]; then
    echo "Starting site-secondary OpenVPN client..."
    if ! command -v openvpn >/dev/null 2>&1; then
        apk add --no-cache openvpn >/dev/null 2>&1 || (apt-get update >/dev/null 2>&1 && apt-get install -y openvpn >/dev/null 2>&1)
    fi
    nohup openvpn --config /etc/openvpn/client-entreprise.conf > /var/log/openvpn-client.log 2>&1 &
    # small wait for tun to come up
    sleep 2
fi

# Politique: VPN-Only → Bloquer le trafic direct vers 120.0.84.0/24 si pas via tun0
# Autoriser le trafic depuis le LAN vers le tunnel tun0

# Reset rules
iptables -F
iptables -t nat -F

# Autoriser loops et état
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Autoriser trafic du LAN vers router (SSH/ICMP)
iptables -A INPUT -s 10.0.2.0/24 -j ACCEPT

# Autoriser les accès internes sortants vers VPN endpoint (UDP 1194)
iptables -A OUTPUT -p udp --dport 1194 -j ACCEPT

# Autoriser le forwarding depuis le LAN vers tun0 et le réseau entreprise via tun0
iptables -A FORWARD -i eth1 -o tun0 -s 10.0.2.0/24 -d 120.0.84.0/24 -j ACCEPT
iptables -A FORWARD -i tun0 -o eth1 -s 120.0.84.0/24 -d 10.0.2.0/24 -j ACCEPT

# Bloquer le forwarding direct LAN -> entreprise (routes directes)
iptables -A FORWARD -s 10.0.2.0/24 -d 120.0.84.0/24 -j DROP

# NAT masquerading pour permettre au LAN d'accéder aux réseaux distants via le tunnel
iptables -t nat -A POSTROUTING -o tun0 -s 10.0.2.0/24 -j MASQUERADE

# Politique par défaut
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "Site secondaire routeur initialisé - VPN-only policy active"

