# Correction REST HTTP/HTTPS

Erreur observée :
`ClientException: Connection closed before full header was received`
sur une URI du type :

`http://10.10.10.1:443/rest/...`

Cette URI est incohérente : le port 443 correspond normalement au service
HTTPS (`www-ssl`). Envoyer une requête HTTP en clair vers un service TLS
provoque souvent une fermeture immédiate de la socket avant qu'un en-tête
HTTP ne soit renvoyé.

RootMikroManager protège maintenant ce cas :

- port 443 + REST sécurisé => `https://...`
- port 80 + REST non sécurisé => `http://...`
- refus explicite de `http://...:443`
- refus explicite de `https://...:80`
- prise en charge des certificats auto-signés pour HTTPS lorsque l'utilisateur
  l'autorise
- messages d'erreur spécifiques pour TLS, Socket et ClientException
- construction centralisée des URI `/rest/...`

MikroTik recommande HTTPS via `www-ssl`.
L'accès REST HTTP via `www` existe sur RouterOS récents mais n'est pas
recommandé en production car l'authentification Basic peut être interceptée.
