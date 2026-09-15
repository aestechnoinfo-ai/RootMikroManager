# Configuration Hotspot native

Ce lot ajoute la gestion native des composants de configuration Hotspot :
- Hotspot Servers ;
- Hotspot Server Profiles ;
- IP Pools ;
- résumé de configuration ;
- accès direct au monitoring des sessions actives.

Les User Profiles restent distincts des Server Profiles. Les vouchers/tickets
restent également distincts des profils.

## Hotspot Server
Nom, interface, address-pool, server-profile, addresses-per-mac,
idle-timeout, keepalive-timeout, login-timeout et état.

## Server Profile
Nom, hotspot-address, dns-name, html-directory, login-by,
http-cookie-lifetime, rate-limit, certificat SSL et RADIUS.

## IP Pool
Nom, ranges et next-pool.
