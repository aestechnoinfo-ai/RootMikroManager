# Gestionnaire — pré-gel logiciel 12

Le test réel est volontairement différé. Cette passe ferme donc la consolidation
logicielle/statique de la branche gestionnaire sans prétendre valider le matériel.

## Ventes
- identité stricte centralisée : date + heure + username + prix + profil ;
- ledger, CA unique, audit qualité et audit sémantique utilisent la même règle ;
- correction d'une ancienne divergence où le ledger n'incluait pas le profil.

## Vouchers
- écran de pré-gel logiciel ;
- séparation explicite génération / vente / réimpression ;
- service d'audit de réimpression prêt à journaliser `voucher.reprinted`
  avec `sale_created=false`.

## PPP
- écran de pré-gel logiciel séparant validation statique et test RouterOS réel.

## Gestionnaire
- écran de gel logiciel ;
- écran de périmètre de validation ;
- les tests MikroTik, portail captif, QR, impression et build restent différés.

Cette étape permet de poursuivre la construction des autres modules sans
confondre « consolidé statiquement » et « validé sur matériel réel ».
