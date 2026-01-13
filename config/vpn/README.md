# Configuration OpenVPN

## Génération des certificats

Avant de lancer le projet, vous devez générer les certificats OpenVPN :

```bash
chmod +x scripts/generate-openvpn-certs.sh
./scripts/generate-openvpn-certs.sh
```

**Note :** Si easy-rsa n'est pas disponible, vous pouvez utiliser un conteneur Docker pour générer les certificats :

```bash
docker run --rm -v $(pwd)/config/vpn:/vpn -it kylemanna/openvpn ovpn_genconfig -u udp://localhost
docker run --rm -v $(pwd)/config/vpn:/vpn -it kylemanna/openvpn ovpn_initpki
```

## Configuration

- **Site Principal (Entreprise 5)** : `config/vpn/openvpn-entreprise5/server.conf`
- **Site Secondaire** : `config/vpn/openvpn-site-secondaire/server.conf`
- **Client Site Secondaire** : `config/vpn/openvpn-entreprise5/client-site-secondaire.conf`

## Utilisation

Les conteneurs OpenVPN monteront automatiquement les configurations.
Pour simplifier, les certificats peuvent être générés après le premier lancement en utilisant les conteneurs.

