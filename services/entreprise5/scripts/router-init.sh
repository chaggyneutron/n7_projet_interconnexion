#!/bin/sh
# Script d'initialisation du routeur entreprise 5

# Activer le forwarding IP
echo 1 > /proc/sys/net/ipv4/ip_forward

# Route vers le VPN (10.8.0.0/24) via le serveur OpenVPN
ip route replace 10.8.0.0/24 via 120.0.84.14

# Route par le routeur de bordure AS5
ip route replace default via 120.0.82.1 dev eth0

# Configuration DHCP (basique via dhcpd si disponible, sinon configuration statique)
# Pour simplifier, on utilise des IPs statiques dans docker-compose

# Configuration iptables - Firewall entreprise
# Autoriser le trafic sortant
iptables -A OUTPUT -j ACCEPT

# Autoriser le trafic entrant pour services spécifiques
# DNS (port 53)
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# HTTP/HTTPS (ports 80, 443)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# SIP (port 5060)
iptables -A INPUT -p udp --dport 5060 -j ACCEPT
iptables -A INPUT -p tcp --dport 5060 -j ACCEPT

# RTP (ports 10000-10020)
iptables -A INPUT -p udp --dport 10000:10020 -j ACCEPT

# OpenVPN (port 1194)
iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# Radius (port 1812)
iptables -A INPUT -p udp --dport 1812 -j ACCEPT

# Autoriser le trafic établi et connexions liées
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Autoriser le trafic depuis le LAN entreprise
iptables -A INPUT -s 120.0.84.0/24 -j ACCEPT

# Autoriser le trafic VPN (10.8.0.0/24) entrant et forwarding
iptables -A INPUT -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT

# Autoriser le trafic depuis l'AS5
iptables -A INPUT -s 120.0.80.0/20 -j ACCEPT

# Autoriser le forwarding entre LAN et AS5
iptables -A FORWARD -s 120.0.84.0/24 -d 120.0.80.0/20 -j ACCEPT
iptables -A FORWARD -s 120.0.80.0/20 -d 120.0.84.0/24 -j ACCEPT

# Rejeter tout le reste
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

# Politique par défaut
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "Routeur entreprise 5 initialisé avec firewall iptables"

