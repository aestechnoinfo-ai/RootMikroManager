# Lot découverte réseau / VPN / RoMON

RootMikroManager sépare clairement les mécanismes de découverte.

## Neighbors
`/ip neighbor` est lu sur le MikroTik connecté. Les entrées MNDP/CDP/LLDP
restent liées au domaine Layer 2 du routeur.

## VPN
WireGuard et BackToHome sont traités comme des réseaux IP routés.
Les interfaces/adresses et peers servent à proposer des CIDR candidats.
ZeroTier est également exploité via ses interfaces et le scan IP afin de
ne pas dépendre des broadcasts Layer 2 côté téléphone.

Ports sondés :
- 8728 RouterOS API
- 8729 RouterOS API TLS
- 8291 Winbox

## RoMON
`/tool romon discover` est exécuté sur le routeur connecté.
Le téléphone n'est pas présenté comme un client RoMON Layer 2 natif.

## Enregistrement
Un hôte trouvé par Neighbor ou scan IP peut être transformé directement
en routeur RootMikroManager, avec groupe et tags de provenance.

## Sécurité scan
Timeout, concurrence et nombre maximal d'hôtes sont bornés pour éviter les
scans accidentellement trop larges.
