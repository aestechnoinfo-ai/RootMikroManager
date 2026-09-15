# RootMikroManager — VPN-aware Neighbor Discovery

RootMikroManager ne suppose plus que tous les MikroTik sont sur le même
LAN Wi-Fi que le téléphone.

## Stratégie

### 1. Neighbors RouterOS
`/ip/neighbor` reste utilisé sur le MikroTik connecté.

Même lorsque ce MikroTik est atteint à travers :
- WireGuard ;
- BackToHome ;
- ZeroTier ;
- 4G/5G + VPN ;

il peut retourner les voisins L2 présents sur ses propres interfaces.

### 2. WireGuard
RootMikroManager inspecte :
- `/interface/wireguard`
- `/interface/wireguard/peers`
- `/ip/address`

Les `allowed-address` et réseaux portés par les interfaces WireGuard
deviennent des candidats de scan.

### 3. BackToHome
BackToHome est basé sur WireGuard. RootMikroManager inspecte :
- `/ip/cloud`
- `/ip/cloud/back-to-home-users`

Le `vpn-interface` et les adresses des clients sont intégrés à la vue VPN.

### 4. ZeroTier
RootMikroManager inspecte :
- `/zerotier/interface`
- `/ip/address`

Les réseaux IP portés par une interface ZeroTier peuvent être scannés pour
les ports :
- 8728 RouterOS API
- 8729 RouterOS API SSL
- 8291 Winbox

### 5. Scan manuel VPN
Une plage CIDR peut être saisie manuellement, par exemple :
- `10.0.10.0/24`
- `172.27.27.0/24`
- `192.168.216.0/24`

Cela couvre notamment les réseaux VPN dont les routes ne peuvent pas être
déduites automatiquement depuis le MikroTik actuellement connecté.

## RoMON

RoMON est un overlay MAC et non un protocole IP routé classique. Un VPN ne
fait donc pas magiquement traverser les trames RoMON.

La stratégie RootMikroManager est :
1. joindre un MikroTik par IP via le VPN ;
2. interroger ce MikroTik ;
3. l'utiliser comme point d'entrée vers son environnement Neighbors/RoMON.

## Limite mobile

La découverte MNDP/LLDP directe depuis Android/iOS nécessitera une couche
native distincte. Le mode VPN-aware actuel privilégie la méthode fiable :
IP routée + RouterOS API + proxy de découverte par le routeur distant.
