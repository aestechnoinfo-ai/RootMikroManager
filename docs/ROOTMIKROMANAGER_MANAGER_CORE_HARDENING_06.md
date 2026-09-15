# Gestionnaire — consolidation 06

Cette passe reste centrée sur Hotspot, vouchers, ventes, historique, impression et PPP.

## Ventes et historique
- registre de ventes normalisé ;
- détection des doublons strictement identiques avant calcul du CA ;
- la réimpression ne crée jamais une vente ;
- export CSV de l’historique local avec profil, validité, prix et devise.

## Hotspot
- synthèse du cycle de vie tickets / actifs / cookies / expirés ;
- nettoyage global explicite : cookie, session active, scheduler utilisateur, puis ticket ;
- compteur des schedulers effectivement supprimés.

## PPP
- blocage des noms de secrets PPP dupliqués avant enregistrement ;
- protection contre la suppression d’un profil encore utilisé par des secrets ou sessions ;
- export sensible des mots de passe reste désactivé par défaut.

## Référence fonctionnelle
Le comportement historique lie la vente au login/record du voucher et utilise un scheduler de profil pour les modes d’expiration. RootMikroManager conserve cette logique tout en ajoutant des contrôles de sécurité et d’intégrité.
