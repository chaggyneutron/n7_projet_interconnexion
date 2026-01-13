# Entreprise 5 - Site Principal

## Description
Ce dossier contient toute la configuration du réseau d'entreprise 5, incluant le routeur, les services (DNS, VoIP, Web, Auth, VPN) et les clients.

## Architecture

```
Entreprise5 Router
    └── LAN Entreprise (120.0.84.0/24)
        ├── DNS (autoritaire pour entreprise5.lan)
        ├── FreeRADIUS (authentification)
        ├── Asterisk (VoIP/SIP)
        ├── Nginx (service web)
        ├── OpenVPN (VPN site-à-site + accès distant)
        ├── DHCP (attribution d'adresses IP)
        └── Clients
```

## Composants

### Routeur
- **entreprise5-router** : Routeur avec firewall iptables
  - Interface vers AS5 : 120.0.82.10
  - Interface LAN : 120.0.84.1 (gateway)

### Services

#### DNS (dns-entreprise5)
- **Type** : Serveur DNS autoritaire
- **Zone** : entreprise5.lan
- **Adresse** : 120.0.84.10
- **Fichiers** :
  - `config/dns/named.conf` : Configuration principale
  - `config/dns/db.entreprise5.lan` : Zone forward
  - `config/dns/db.84.0.120` : Zone reverse

#### FreeRADIUS (radius-entreprise5)
- **Rôle** : Authentification centralisée
- **Adresse** : 120.0.84.11
- **Port** : 1812/udp
- **Fichiers** :
  - `config/radius/clients.conf` : Clients autorisés
  - `config/radius/users` : Utilisateurs

#### Asterisk (asterisk-entreprise5)
- **Rôle** : Serveur VoIP/SIP
- **Adresse** : 120.0.84.12
- **Ports** :
  - 5060/udp : SIP
  - 10000-10020/udp : RTP
- **Extensions** : 1001, 1002
- **Fichiers** :
  - `config/asterisk/asterisk.conf` : Configuration principale
  - `config/asterisk/sip.conf` : Configuration SIP
  - `config/asterisk/extensions.conf` : Plan de numérotation

#### Nginx (nginx-entreprise5)
- **Rôle** : Serveur web
- **Adresse** : 120.0.84.13
- **Port** : 80 (exposé sur 8081)
- **Fichiers** :
  - `config/nginx/nginx.conf` : Configuration Nginx
  - `config/nginx/html/` : Fichiers web

#### OpenVPN (openvpn-entreprise5)
- **Rôle** : Serveur VPN
- **Adresse** : 120.0.84.14
- **Port** : 1194/udp
- **Réseau VPN** : 10.8.0.0/24
- **Fichiers** :
  - `config/vpn/server.conf` : Configuration serveur
  - `config/vpn/*.crt` : Certificats
  - `config/vpn/*.key` : Clés

#### DHCP (dhcp-entreprise5)
- **Rôle** : Serveur DHCP pour attribution d'adresses IP
- **Adresse** : 120.0.84.15
- **Port** : 67/udp
- **Plage** : 120.0.84.100 - 120.0.84.200
- **Fichiers** :
  - `config/dhcp/dhcpd.conf` : Configuration DHCP

### Clients
- **client-entreprise5-1** : 120.0.84.100
- **client-entreprise5-2** : 120.0.84.101

## Configuration

### Structure
```
entreprise5/
├── docker-compose.yml
├── README.md
├── config/
│   ├── dns/
│   ├── radius/
│   ├── asterisk/
│   ├── nginx/
│   ├── vpn/
│   └── dhcp/
└── scripts/
    └── router-init.sh
```

## Services Exposés

| Service | Port Externe | Port Interne | Description |
|---------|--------------|-------------|-------------|
| Nginx | 8081 | 80 | Service web |
| Asterisk SIP | 5060 | 5060 | VoIP |
| Asterisk RTP | 10000-10020 | 10000-10020 | Media VoIP |
| OpenVPN | 1194 | 1194 | VPN |

## Commandes Utiles

```bash
# Démarrer tous les services entreprise
docker compose -f services/entreprise5/docker-compose.yml up -d

# Vérifier les services
docker compose -f services/entreprise5/docker-compose.yml ps

# Tester le DNS
docker exec client-entreprise5-1 nslookup www.entreprise5.lan 120.0.84.10

# Tester le service web
docker exec client-entreprise5-1 curl http://nginx-entreprise5.entreprise5.lan

# Tester FreeRADIUS
docker exec radius-entreprise5 radtest user1 password1 127.0.0.1 0 testing123
```

## Maintenance

Pour modifier un service :
1. Éditer les fichiers dans `config/<service>/`
2. Redémarrer le service : `docker compose restart <service-name>`

