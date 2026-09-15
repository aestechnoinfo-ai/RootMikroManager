# Gestionnaire — consolidation 05

Cette passe reste centrée sur la gestion Hotspot, vouchers, rapports et PPP.

## Hotspot / vouchers
- contrôle complet d’un voucher par username : ticket routeur, actif, cookie, scheduler, historique local et vente ;
- réparation sélective des tickets déjà expirés ;
- ordre destructif renforcé : cookies, sessions actives, scheduler, puis ticket ;
- audit/réparation des schedulers de surveillance des profils avec expiration ;
- génération alignée sur la limite historique de 99 vouchers par lot.

## Rapports
- nouveau parseur de dates compatible avec RouterOS récent (`YYYY-MM-DD`) et formats historiques (`MM/DD/YYYY`, `mon/DD/YYYY`) ;
- filtres Jour/Mois désormais appliqués localement aux enregistrements réels au lieu de dépendre uniquement de `source`/`owner` ;
- Resume Report et son PDF utilisent le même parseur ;
- export CSV entre deux dates exactes ;
- audit non destructif des ventes strictement dupliquées et estimation du montant potentiellement compté deux fois.

## PPP
- audit des sessions actives sans secret PPP correspondant, avec déconnexion manuelle confirmée ;
- audit non destructif des profils PPP inutilisés ;
- aucune donnée de mot de passe n’est affichée par ces audits.

## Hygiène du service
- suppression d’une déclaration `queueTree` dupliquée ;
- `disconnectPppActive` reste unique.
