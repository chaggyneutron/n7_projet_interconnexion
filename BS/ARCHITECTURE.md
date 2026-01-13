# Architecture Détaillée du Projet

## 📐 Schéma d'Adressage IP Complet

### AS5 (120.0.80.0/20)

| Réseau | Plage | Description | Gateway |
|--------|-------|-------------|---------|
| Backbone AS5 | 120.0.80.0/24 | Liens entre routeurs AS5 | - |
| Lien Internet | 120.0.81.0/24 | AS5 ↔ Internet Router | - |
| Lien Entreprise | 120.0.82.0/24 | AS5 ↔ Entreprise Router | - |
| Lien Particulier | 120.0.83.0/24 | AS5 ↔ Particulier Box | - |
| LAN Entreprise | 120.0.84.0/24 | Réseau interne entreprise | 120.0.84.1 |
| Services AS5 | 120.0.85.0/24 | Services centraux AS5 | 120.0.85.1 |

### Réseaux Externes

| Réseau | Plage | Description | Gateway |
|--------|-------|-------------|---------|
| Backbone Internet | 10.0.0.0/24 | Réseau Internet simulé | 10.0.0.1 |
| Lien Site Secondaire | 10.0.1.0/24 | Internet ↔ Site Secondaire | - |
| LAN Site Secondaire | 10.0.2.0/24 | Réseau site secondaire | 10.0.2.1 |
| LAN Particulier | 192.168.5.0/24 | Réseau domestique (NAT) | 192.168.5.1 |

## 🗺️ Topologie Complète

```
                    ┌─────────────────┐
                    │ Internet Router │
                    │   (AS1 - BGP)   │
                    │   10.0.0.1      │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
            ┌───────┴───────┐  ┌──────┴────────┐
            │               │  │               │
    ┌───────▼───────┐  ┌───▼───┐    ┌────────▼────────┐
    │  AS5-Border   │  │       │    │ Site Secondaire │
    │   Router      │  │       │    │     Router      │
    │ 120.0.80.1    │  │       │    │   10.0.1.10     │
    └───────┬───────┘  │       │    └────────┬────────┘
            │          │       │             │
    ┌───────┴───────┐  │       │    ┌────────▼────────┐
    │               │  │       │    │ Site Secondaire │
    │               │  │       │    │      LAN        │
    │               │  │       │    │   10.0.2.0/24   │
    │               │  │       │    │                 │
    │  ┌──────────┐ │  │       │    │ - Client 1       │
    │  │AS5-      │ │  │       │    │ - OpenVPN       │
    │  │Internal  │ │  │       │    └─────────────────┘
    │  │120.0.80.2│ │  │       │
    │  └────┬─────┘ │  │       │
    │       │       │  │       │
    │  ┌────▼─────┐ │  │       │
    │  │Services │ │  │       │
    │  │AS5      │ │  │       │
    │  │120.0.85 │ │  │       │
    │  │         │ │  │       │
    │  │- DNS    │ │  │       │
    │  └─────────┘ │  │       │
    │               │  │       │
    │  ┌──────────┐ │  │       │
    │  │Entreprise│ │  │       │
    │  │Router    │ │  │       │
    │  │120.0.82.10│ │  │       │
    │  └────┬─────┘ │  │       │
    │       │       │  │       │
    │  ┌────▼─────┐ │  │       │
    │  │Entreprise│ │  │       │
    │  │LAN       │ │  │       │
    │  │120.0.84.0│ │  │       │
    │  │          │ │  │       │
    │  │- DNS     │ │  │       │
    │  │- Radius  │ │  │       │
    │  │- Asterisk│ │  │       │
    │  │- Nginx   │ │  │       │
    │  │- OpenVPN │ │  │       │
    │  │- Clients │ │  │       │
    │  └──────────┘ │  │       │
    │               │  │       │
    │  ┌──────────┐ │  │       │
    │  │Particulier│ │  │       │
    │  │Box       │ │  │       │
    │  │120.0.83.10│ │  │       │
    │  └────┬─────┘ │  │       │
    │       │       │  │       │
    │  ┌────▼─────┐ │  │       │
    │  │Particulier│ │  │       │
    │  │LAN       │ │  │       │
    │  │192.168.5 │ │  │       │
    │  │          │ │  │       │
    │  │- Clients │ │  │       │
    │  └──────────┘ │  │       │
    │               │  │       │
    └───────────────┘  │       │
                       │       │
                       └───────┘
```

## 🔄 Protocoles de Routage

### OSPF (Interne AS5)

- **Area 0** : Tous les réseaux AS5
- **Routeurs** :
  - AS5-Border (Router-ID: 120.0.80.1)
  - AS5-Internal (Router-ID: 120.0.80.2)
- **Réseaux annoncés** :
  - 120.0.80.0/24 (Backbone)
  - 120.0.81.0/24 (Lien Internet)
  - 120.0.82.0/24 (Lien Entreprise)
  - 120.0.83.0/24 (Lien Particulier)
  - 120.0.85.0/24 (Services)

### BGP (Externe)

- **AS5-Border ↔ Internet Router** :
  - AS5-Border : AS 5
  - Internet Router : AS 1
  - Route annoncée : 120.0.80.0/20

- **iBGP (Interne)** :
  - AS5-Border ↔ AS5-Internal
  - Synchronisation des routes externes

## 🛡️ Sécurité et Filtrage

### Routeur Entreprise

**Règles iptables** :
- ✅ Autorise : DNS (53), HTTP/HTTPS (80/443), SIP (5060), RTP (10000-10020), OpenVPN (1194), Radius (1812)
- ✅ Autorise : Trafic depuis LAN (120.0.84.0/24) et AS5 (120.0.80.0/20)
- ❌ Bloque : Tout le reste

### NAT

- **AS5-Border** : Masquerade pour 120.0.80.0/20 → Internet
- **Particulier5-Box** : Masquerade pour 192.168.5.0/24 → AS5

## 📊 QoS (Quality of Service)

### Configuration sur AS5-Border

**Interface vers Entreprise (eth2)** :
- Classe 1 (Haute priorité) : 80 Mbit/s garantis, 100 Mbit/s max
  - Filtre : src/dst 120.0.84.0/24
- Classe 2 (Normale) : 20 Mbit/s garantis, 100 Mbit/s max
  - Filtre : Autre trafic

**Interface vers Particulier (eth3)** :
- Classe 3 (Normale) : 50 Mbit/s garantis
  - Filtre : src/dst 120.0.83.0/24

## 🌐 Services

### DNS

1. **DNS AS5 (Récursif)** - 120.0.85.10
   - Forwarders : 8.8.8.8, 8.8.4.4
   - Accessible depuis : 120.0.80.0/20, 192.168.5.0/24

2. **DNS Entreprise (Autoritaire)** - 120.0.84.10
   - Zone : entreprise5.lan
   - Accessible depuis : 120.0.84.0/24

### FreeRADIUS - 120.0.84.11

- Port : 1812 (UDP)
- Utilisateurs : user1, user2, admin
- Clients autorisés : 120.0.84.0/24

### Asterisk (VoIP) - 120.0.84.12

- Port SIP : 5060 (UDP)
- Ports RTP : 10000-10020 (UDP)
- Extensions : 1001, 1002
- Secrets : 1001pass, 1002pass

### Nginx (Web) - 120.0.84.13

- Port : 80
- Accessible : http://nginx-entreprise5.entreprise5.lan
- Page d'accueil : Services Entreprise 5

### OpenVPN

1. **Serveur Entreprise** - 120.0.84.14
   - Port : 1194 (UDP)
   - Réseau VPN : 10.8.0.0/24
   - Routes pushées : 120.0.84.0/24, 120.0.80.0/20

2. **Serveur Site Secondaire** - 10.0.2.11
   - Port : 1194 (UDP)
   - Réseau VPN : 10.9.0.0/24
   - Routes pushées : 10.0.2.0/24, 120.0.84.0/24

## 🔌 Connexions VPN

### Site-à-Site

- **Site Principal** ↔ **Site Secondaire**
- Tunnel OpenVPN entre les deux sites
- Connectivité bidirectionnelle des réseaux

### Accès Distant

- **Particulier 5** → **Réseau Entreprise**
- Client OpenVPN sur la Box Particulier
- Accès sécurisé aux services entreprise

## 📝 Notes Techniques

1. **Privilèges** : Les routeurs et boxes nécessitent `privileged: true` et `NET_ADMIN` pour :
   - Routage IP
   - NAT/Masquerade
   - QoS (tc)
   - iptables

2. **Forwarding IP** : Activé sur tous les routeurs via `sysctls` et scripts

3. **Résolution DNS** : Configuration automatique via `scripts/client-init.sh`

4. **Certificats OpenVPN** : Nécessaires pour le fonctionnement du VPN (voir `config/vpn/README.md`)

