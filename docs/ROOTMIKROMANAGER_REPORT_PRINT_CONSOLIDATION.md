# Consolidation rapports, exports et impressions

Cette phase unifie la présentation monétaire et les réglages vouchers entre :
- écran Selling Report ;
- export CSV ;
- impression/PDF du Selling Report ;
- génération de vouchers ;
- réimpression depuis l'historique ;
- impression depuis un utilisateur Hotspot ;
- impression depuis la liste des utilisateurs Hotspot.

## Devise

Tous les montants utilisent `AppCurrencySettings`.
Le CSV conserve deux colonnes distinctes `Price` et `Currency`.
Le PDF affiche la devise sur les lignes, le total et le résumé par profil.

## Vouchers

Tous les points d'entrée chargent `VoucherTemplateSettings` avant impression.
Les choix d'affichage et la densité 1 à 50 tickets/page sont donc identiques
quelle que soit l'origine de l'impression.

L'historique local enregistre maintenant aussi `selling_price` et `validity`
pour permettre une réimpression plus fidèle des nouveaux vouchers. Une
migration SQLite ajoute ces colonnes aux bases existantes sans effacer les
anciens enregistrements.
