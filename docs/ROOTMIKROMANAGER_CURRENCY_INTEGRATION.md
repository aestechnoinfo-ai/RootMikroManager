# Devise RootMikroManager

La devise est un paramètre partagé au niveau de l'application.

Clé principale SQLite :
- `app_currency`

Compatibilité :
- la clé locale `voucher_currency` est migrée automatiquement ;
- les deux clés restent synchronisées pendant la migration.

La devise est utilisée dans :
- Selling Report ;
- total des ventes ;
- résumé par profil ;
- montant individuel de chaque vente ;
- export CSV avec colonnes `Price` et `Currency` ;
- modèles vouchers ;
- aperçu des vouchers ;
- PDF / impression ;
- aperçu des prix dans le générateur ;
- écrans Hotspot affichant un prix.

Un changement dans l'éditeur de vouchers met donc à jour la devise globale
utilisée par les rapports et les impressions.
