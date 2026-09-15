# Gestionnaire — consolidation 07

Cette passe reste exclusivement sur la partie gestionnaire RootMikroManager.

## Tickets / vouchers
- service centralisé de cycle de vie d'un ticket ;
- nettoyage cookie + session avant reset/suppression ;
- suppression du scheduler utilisateur avant suppression du ticket ;
- le profil Hotspot référencé n'est jamais supprimé par une action sur un ticket ;
- nouvelle fiche détaillée accessible depuis le catalogue des tickets.

## Ventes / rapports
- synthèse de cohérence des ventes ;
- séparation ventes brutes, ventes uniques, doublons stricts et lignes invalides ;
- chiffre d'affaires calculé uniquement à partir des ventes valides et non dupliquées ;
- hub central Exports & impression pour Selling Report, User Log, Resume mensuel,
  période exacte et historique vouchers ;
- la réimpression ne crée aucune vente.

## PPP
- audit de cohérence profils / secrets / pools ;
- audit de cohérence des secrets sans révéler les mots de passe ;
- contrôles supplémentaires sur profils référencés et services PPP.

## Sécurité fonctionnelle Hotspot
Une suppression de ticket suit toujours l'ordre :
1. cookie ;
2. session active ;
3. scheduler utilisateur ;
4. ticket.

Les profils Hotspot (/ip/hotspot/user/profile) restent distincts des tickets
(/ip/hotspot/user).
