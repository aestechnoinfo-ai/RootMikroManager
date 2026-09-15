# VPN — intégration réelle & sécurité

- Intégration RouterOS pour WireGuard, ZeroTier, Back To Home et `/ip/neighbor`.
- CRUD WireGuard peers sans affichage de clés privées.
- CRUD ZeroTier avec avertissement `allow-default`.
- Back To Home en lecture sûre, sans QR/config/secret.
- Neighboring VPN basé sur les Allowed Address/endpoints/réseaux comme candidats IP.
- `/ip/neighbor` est interrogé depuis un routeur RouterOS joignable.
- Navigation VPN visible depuis le hub Interfaces.
- MNDP/CDP/LLDP restent des mécanismes L2 ; aucun faux voisinage L2 n’est supposé à travers WireGuard/Back To Home.
