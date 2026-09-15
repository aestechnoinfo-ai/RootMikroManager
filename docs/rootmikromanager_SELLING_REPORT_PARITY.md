# Selling Report - parité RootMikroManager officiel

Référence : `report/selling.php` du dépôt officiel `laksa19/rootmikromanagerv3`.

RootMikroManager enregistre les ventes dans `/system script`, pas dans un module de
comptabilité :
- `comment=rootmikromanager` pour l'ensemble ;
- `source=<date>` pour le filtre journalier ;
- `owner=<mois><année>` pour le filtre mensuel ;
- le nom du script est structuré avec `-|-`.

Les positions encodent date, heure, username, prix, adresse, MAC, validité,
profil et commentaire.

RootMikroManager ajoute :
- Tout / Jour / Mois ;
- recherche username / profil / commentaire ;
- total ;
- résumé par profil ;
- export CSV ;
- Remove Data avec confirmation.

Par sécurité, Remove Data est interdit en vue Tout. L'historique SQLite des
vouchers reste distinct du Selling Report et n'est pas présenté comme une
comptabilité.
