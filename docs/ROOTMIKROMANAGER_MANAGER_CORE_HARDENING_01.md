# Gestionnaire Hotspot / PPP / Rapports / Impression — consolidation 01

Priorité actuelle : terminer la partie gestionnaire avant les fonctions réseau avancées.

## Hotspot / vouchers
- prévisualisation d'un lot par commentaire exact ;
- nettoyage de lot : cookie + session active + scheduler avant suppression du ticket ;
- reset d'un ticket : nettoyage cookie/session avant remise à zéro ;
- nettoyage confirmé des cookies orphelins ;
- séparation profils Hotspot / tickets maintenue ;
- devise globale corrigée dans le catalogue des profils.

## PPP
- suppression du doublon `disconnectPppActive` dans RouterOsService ;
- audit secrets/profils/pools/sessions ;
- détection simple de doublons et références absentes.

## Rapports
- audit d'intégrité des ventes ;
- contrôle prix, profil, username, date et devise ;
- total valide affiché avec devise.

## Impression
Les écrans existants conservent QR, layouts, templates, PDF et prix/devise. Les prochaines passes doivent renforcer formats papier et réimpression/partage sans introduire de dépendance file_picker.
