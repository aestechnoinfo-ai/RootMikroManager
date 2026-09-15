# Gestionnaire — consolidation 08

Cette passe reste exclusivement sur la partie gestionnaire RootMikroManager.

## Hotspot / vouchers
- résultat structuré par ticket pour les opérations en lot ;
- suppression et reset centralisés ;
- visibilité des échecs partiels ;
- nettoyage expiration et lots exacts via le même service de cycle de vie ;
- ordre de suppression : cookie, session active, scheduler utilisateur, ticket ;
- aucun profil Hotspot supprimé lors d'une opération sur un ticket.

## Rapports / ventes
- nouveau service de nettoyage des ventes par période normalisée ;
- compatibilité avec formats de date historiques et ISO ;
- aperçu jour/mois avant suppression ;
- le montant concerné est affiché avec la devise globale ;
- Remove Data du Selling Report utilise maintenant les enregistrements réellement
  sélectionnés après parsing de date et non une égalité brute source/owner ;
- le nettoyage des rapports ne supprime jamais les vouchers.

## PPP
- blocage de suppression d'un secret lorsqu'une session correspondante est active ;
- audit dédié des actions destructives PPP ;
- la suppression d'un profil reste bloquée lorsqu'il est utilisé.

## Vérifications
- séparation stricte ticket / profil ;
- réimpression distincte de la vente ;
- mots de passe PPP non exposés par les nouveaux audits.
