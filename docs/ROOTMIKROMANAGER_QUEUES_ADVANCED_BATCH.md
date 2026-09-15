# Queues avancé

Ce lot complète le module Queues avec :
- Simple Queues existantes ;
- Queue Tree avec éditeur dédié ;
- Queue Types ;
- monitoring ;
- statistiques ;
- détails complets des propriétés RouterOS.

## Queue Types
Support d'édition pour les types principaux, notamment PCQ avec rate,
classifier, limit et total-limit. Les types par défaut restent affichés mais
ne sont pas supprimés depuis RootMikroManager.

## Monitoring
Actualisation configurable de 1 à 300 secondes, suspendue lorsque
l'application passe en arrière-plan. Affichage conditionnel des octets et
paquets.

## Queue Tree
Éditeur dédié : parent, packet-mark, queue type, limit-at, max-limit,
burst-limit, burst-threshold, burst-time, priority, commentaire et état.
