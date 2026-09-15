# Gestionnaire — consolidation 02

Cette passe reste exclusivement sur la partie gestionnaire Hotspot / vouchers / rapports / impression.

## Expiration Hotspot
- audit des tickets marqués expirés (`limit-uptime=1s`) ;
- détection des cookies encore associés ;
- détection des sessions actives encore associées ;
- contrôle simple des profils avec validité et scheduler de surveillance ;
- la règle cookie + session avant suppression reste obligatoire.

## Rapports
- User Log : impression/PDF A4 ;
- Resume Report mensuel : impression/PDF A4 ;
- Resume Report : export CSV avec devise ;
- les totaux utilisent la devise globale.

## Impression vouchers
- format imprimante ;
- A4 ;
- thermique 80 mm ;
- thermique 58 mm ;
- densité thermique automatiquement limitée à 2 tickets/page ;
- audit de préparation : QR, URL Login, devise, densité et papier ;
- QR conservé hors très forte densité selon le moteur existant.

## Parité fonctionnelle
La structure conserve l'approche historique : profils Hotspot + métadonnées business + scripts on-login + scheduler de surveillance, tout en ajoutant les protections nécessaires aux cookies et sessions RouterOS actuels.
