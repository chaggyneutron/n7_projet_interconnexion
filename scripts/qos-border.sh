#!/bin/sh
# Script de configuration QoS sur le routeur de bordure AS5
# Priorise le trafic entreprise par rapport aux particuliers

# Interface vers entreprise (eth2)
# Classe 1: Trafic entreprise (haute priorité)
tc qdisc add dev eth2 root handle 1: htb default 30
tc class add dev eth2 parent 1: classid 1:1 htb rate 100mbit
tc class add dev eth2 parent 1:1 classid 1:10 htb rate 80mbit ceil 100mbit prio 1
tc class add dev eth2 parent 1:1 classid 1:20 htb rate 20mbit ceil 100mbit prio 2
tc filter add dev eth2 protocol ip parent 1:0 prio 1 u32 match ip src 120.0.84.0/24 flowid 1:10
tc filter add dev eth2 protocol ip parent 1:0 prio 2 u32 match ip dst 120.0.84.0/24 flowid 1:10

# Interface vers particulier (eth3)
# Classe 2: Trafic particulier (priorité normale)
tc qdisc add dev eth3 root handle 1: htb default 30
tc class add dev eth3 parent 1: classid 1:1 htb rate 50mbit
tc class add dev eth3 parent 1:1 classid 1:30 htb rate 50mbit ceil 50mbit prio 3
tc filter add dev eth3 protocol ip parent 1:0 prio 3 u32 match ip src 120.0.83.0/24 flowid 1:30
tc filter add dev eth3 protocol ip parent 1:0 prio 3 u32 match ip dst 120.0.83.0/24 flowid 1:30

echo "QoS configuré sur AS5-Border (priorité entreprise > particulier)"

