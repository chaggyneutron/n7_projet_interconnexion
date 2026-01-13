# Projet Simulation Réseau - AS5 (Groupe 5)

## 📋 Vue d'ensemble

Ce projet simule une architecture réseau complète utilisant Docker Compose, incluant :
- **Système Autonome AS5** (plage IP : 120.0.80.0/20)
- **Réseau d'entreprise** avec services (DNS, VoIP, Web, Radius, VPN)
- **Client particulier** (Box-like avec NAT)
- **Site secondaire** connecté via VPN
- **Routage dynamique** (OSPF interne, BGP externe)

## 🏗️ Structure Modulaire

Le projet est organisé de manière **hiérarchique et modulaire** pour faciliter le travail en équipe :

```
services/
├── as5-routers/        # Routeurs AS5 (OSPF/BGP)
├── internet-router/    # Routeur Internet/AS1
├── dns-as5/            # DNS récursif AS5
├── entreprise5/        # Site principal entreprise
├── particulier5/       # Box et clients particuliers
└── site-secondaire/    # Site secondaire
```

**Chaque service a son propre dossier avec :**
- `README.md` : Documentation du service
- `docker-compose.yml` : Configuration Docker
- `config/` : Fichiers de configuration
- `scripts/` : Scripts d'initialisation (si nécessaire)

👉 **Voir `README_STRUCTURE.md` pour la structure complète**

## 🚀 Démarrage Rapide

### Option 1 : Script Automatique

```bash
./start-all.sh
```

### Option 2 : Manuel

```bash
# 1. Créer les réseaux
docker compose up -d --no-start

# 2. Lancer les services
docker compose -f services/as5-routers/docker-compose.yml up -d
docker compose -f services/internet-router/docker-compose.yml up -d
docker compose -f services/dns-as5/docker-compose.yml up -d
docker compose -f services/entreprise5/docker-compose.yml up -d
docker compose -f services/particulier5/docker-compose.yml up -d
docker compose -f services/site-secondaire/docker-compose.yml up -d
```

👉 **Voir `GUIDE_DEMARRAGE.md` pour plus de détails**

## 📚 Documentation

- **`README_STRUCTURE.md`** : Structure hiérarchique du projet
- **`GUIDE_DEMARRAGE.md`** : Guide de démarrage rapide
- **`ARCHITECTURE.md`** : Architecture détaillée
- **`services/<service>/README.md`** : Documentation de chaque service

## 🧪 Tests

```bash
# Tests de connectivité
./scripts/test-connectivity.sh

# Tests complets
./scripts/test-complete.sh

# Tests VPN
./scripts/test-vpn-http.sh
```

## 👥 Travail en Équipe

Chaque membre peut travailler sur un service spécifique :
- **Membre 1** : `services/as5-routers/`
- **Membre 2** : `services/entreprise5/`
- **Membre 3** : `services/particulier5/` + `services/site-secondaire/`
- **Membre 4** : `services/dns-as5/` + Tests

## 📊 Adressage IP

### AS5 (120.0.80.0/20)
- 120.0.80.0/24 : Backbone AS5
- 120.0.81.0/24 : Lien Internet
- 120.0.82.0/24 : Lien Entreprise
- 120.0.83.0/24 : Lien Particulier
- 120.0.84.0/24 : LAN Entreprise
- 120.0.85.0/24 : Services AS5

### Réseaux Externes
- 10.0.0.0/24 : Backbone Internet
- 10.0.1.0/24 : Lien Site Secondaire
- 10.0.2.0/24 : LAN Site Secondaire
- 192.168.5.0/24 : LAN Particulier

## 🔧 Services

| Service | Port | Description |
|---------|------|-------------|
| Nginx | 8081 | Service web |
| Asterisk SIP | 5060 | VoIP |
| OpenVPN Entreprise | 1194 | VPN |
| OpenVPN Site Secondaire | 1195 | VPN |
| DNS | 53 | Résolution DNS |

## 📝 Notes Importantes

1. **Certificats OpenVPN** : Générer avant utilisation (voir `services/entreprise5/README.md`)
2. **Routeurs** : Nécessitent des privilèges root (`privileged: true`)
3. **Réseaux** : Créés par le `docker-compose.yml` principal

## 🐛 Dépannage

Voir `GUIDE_DEMARRAGE.md` section "Dépannage" ou les README de chaque service.

---

**Projet créé pour le Groupe 5 - Simulation Réseau**
