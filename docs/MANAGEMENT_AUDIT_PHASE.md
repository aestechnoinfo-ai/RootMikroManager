# RootMikroManager — Management & Audit Phase

## Multi-routeurs
- groupes ;
- tags ;
- recherche ;
- filtres par groupe ;
- migration SQLite v4 ;
- édition complète.

## Scan réseau
Un scan IPv4 /24 est ajouté pour détecter rapidement les équipements
présentant les ports généralement utilisés par MikroTik :

- 8728 : RouterOS API ;
- 8729 : RouterOS API SSL ;
- 8291 : Winbox.

Ce scan est complémentaire au Neighbor Discovery RouterOS. Il ne remplace
pas MNDP/LLDP L2 natif.

## Journal d’audit
Le journal local suit notamment :
- création de routeur ;
- modification ;
- suppression ;
- import de sauvegarde ;
- backup RouterOS ;
- export RouterOS.

Une page Audit permet de consulter et vider ce journal.

## Sauvegarde / restauration
- export JSON applicatif ;
- restauration depuis JSON collé ;
- mode fusion ;
- mode remplacement complet ;
- contrôle du format RootMikroManager.

## Objectif
Continuer la construction fonctionnelle complète. L’APK reste hors du
périmètre jusqu’à la phase finale.
