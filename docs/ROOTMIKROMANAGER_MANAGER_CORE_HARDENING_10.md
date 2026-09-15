# Gestionnaire — consolidation 10

Cette passe continue la fermeture fonctionnelle de la branche gestionnaire.

## Vouchers / portail
- URL du portail captif validée avant usage QR ;
- audit dédié QR et portail ;
- écran de sémantique distinguant génération, présence RouterOS, vente et réimpression ;
- libellé de génération uniformisé à 1–99 tickets.

## PPP
- validation centralisée des secrets PPP ;
- contrôle du service, du profil, des IP/pools et des doublons ;
- audit de préparation export rappelant que les mots de passe doivent être exclus par défaut.

## Ventes
- calcul non destructif du chiffre d'affaires dédupliqué ;
- déduplication stricte date + heure + username + prix + profil ;
- devise globale utilisée pour le montant.

## Sécurité
- aucune réimpression n'écrit de vente ;
- aucun audit ne supprime automatiquement les données ;
- tickets et profils Hotspot restent strictement distincts.
