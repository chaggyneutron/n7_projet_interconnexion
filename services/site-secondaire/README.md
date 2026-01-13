# Site Secondaire

## Description
Ce dossier contient la configuration du site secondaire de l'entreprise, connecté via Internet et accessible via VPN.

## Architecture

```
Site Secondaire Router (10.0.1.10)
    └── LAN Site Secondaire (10.0.2.0/24)
        ├── client-site-secondaire-1 (10.0.2.10)
        └── openvpn-site-secondaire (10.0.2.11)
```

## Composants

### site-secondaire-router
- **Rôle** : Routeur du site secondaire
- **Interfaces** :
  - `eth0` : Lien vers Internet (10.0.1.10)
  - `eth1` : LAN site secondaire (10.0.2.1)

### openvpn-site-secondaire
- **Rôle** : Serveur OpenVPN du site secondaire
- **Adresse** : 10.0.2.11
- **Port** : 1194/udp (exposé sur 1195)
- **Réseau VPN** : 10.9.0.0/24

### client-site-secondaire-1
- **Rôle** : Client du site secondaire
- **Adresse** : 10.0.2.10

## Configuration

### Fichiers
- `docker-compose.yml` : Définition des conteneurs
- `config/vpn/` : Configuration OpenVPN
- `scripts/router-init.sh` : Script d'initialisation routeur

## VPN Site-à-Site

Le site secondaire peut se connecter au site principal via OpenVPN pour établir un tunnel sécurisé.

## Commandes Utiles

```bash
# Tester la connectivité
docker exec client-site-secondaire-1 ping -c 2 10.0.2.1

# Tester le VPN (vers site principal)
docker exec client-site-secondaire-1 curl http://120.0.84.13
```

