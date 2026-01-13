# Particulier 5 - Box et Clients

## Description
Ce dossier contient la configuration de la Box Particulier 5 (simulation d'une box Internet) et de ses clients.

## Architecture

```
Particulier5 Box (120.0.83.10)
    └── LAN Particulier (192.168.5.0/24)
        ├── client-particulier5-1 (192.168.5.10)
        └── client-particulier5-2 (192.168.5.11)
```

## Composants

### particulier5-box
- **Rôle** : Box Internet (simulation)
- **Fonctions** :
  - NAT/Masquerade pour le LAN domestique
  - Gateway pour les clients
  - Connexion à l'AS5
- **Interfaces** :
  - `eth0` : Lien vers AS5 (120.0.83.10)
  - `eth1` : LAN domestique (192.168.5.1)

### Clients
- **client-particulier5-1** : 192.168.5.10
- **client-particulier5-2** : 192.168.5.11

## Configuration

### Fichiers
- `docker-compose.yml` : Définition des conteneurs
- `scripts/box-init.sh` : Script d'initialisation (NAT, iptables)

## NAT/Masquerade

La Box fait du NAT pour permettre aux clients du LAN domestique d'accéder à Internet via l'AS5.

```bash
# Règle NAT
iptables -t nat -A POSTROUTING -o eth0 -s 192.168.5.0/24 -j MASQUERADE
```

## Commandes Utiles

```bash
# Vérifier le NAT
docker exec particulier5-box iptables -t nat -L POSTROUTING

# Tester depuis un client
docker exec client-particulier5-1 ping -c 2 120.0.83.1
docker exec client-particulier5-1 curl http://nginx-entreprise5.entreprise5.lan
```

