# Scripts & Scheduler avancés

Ce lot ajoute :
- gestion complète des scripts RouterOS ;
- exécution manuelle ;
- détails et compteurs ;
- gestion complète du Scheduler ;
- prochaine exécution, intervalle et run-count ;
- visualisation des liaisons Scheduler → Script ;
- référence des policies ;
- résumé automatisation.

Les éditeurs existants ont été renforcés avec une sélection explicite des
policies RouterOS :
ftp, reboot, read, write, policy, test, password, sniff, sensitive et romon.

## Permissions
RouterOS peut empêcher un Scheduler d'exécuter un script si ses permissions ne
sont pas suffisantes. `dont-require-permissions` reste disponible pour les
scripts, mais RootMikroManager le présente comme une option sensible.

## Compatibilité
Le Scheduler reste compatible avec les mécanismes d'expiration et de monitoring
des profils Hotspot déjà présents dans l'application. Les scripts de vente et
les schedulers associés ne sont pas fusionnés avec les profils ou vouchers.
