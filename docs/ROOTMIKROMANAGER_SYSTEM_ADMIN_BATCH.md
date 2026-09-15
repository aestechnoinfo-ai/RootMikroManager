# Lot Système / Scripts / Scheduler / Packages / Health / NTP

## Vue générale
Identity, RouterOS, RouterBOARD, numéro de série, firmware, architecture,
plateforme, date/heure/fuseau, uptime, CPU, RAM et stockage.

## Santé matériel
Lecture `/system health` avec signalement couleur de la température et
compatibilité avec les routeurs ne disposant pas de capteurs.

## Stockage
Résumé espace libre/total et explorateur `/file` avec recherche et suppression.

## Packages
Liste `/system package`, statut de `/system package update`, vérification et
installation de mise à jour. Les opérations de package pouvant nécessiter un
redémarrage restent présentées comme telles.

## NTP
Activation, mode et serveurs du client `/system ntp client`.

## Scripts
Éditeur dédié : nom, source, commentaire et
`dont-require-permissions`, exécution manuelle et suppression.

## Scheduler
Éditeur dédié : nom, start-date, start-time, interval, on-event,
commentaire et état activé/désactivé.
