# Logs & journalisation avancés

Ce lot ajoute :
- lecture filtrée de `/log` ;
- recherche et filtrage par topic ;
- auto-refresh toutes les 5 secondes ;
- règles `/system/logging` ;
- actions `/system/logging/action` ;
- targets memory, disk, remote, echo et email ;
- réglages remote syslog / CEF ;
- résumé global.

## Topics
Les règles acceptent plusieurs topics séparés par des virgules.
Le préfixe `!` est conservé afin d'exclure un topic.

## Remote logging
L'éditeur prend en charge UDP, TCP et TLS ainsi que les formats default,
syslog et CEF. Les versions RouterOS peuvent exposer certaines propriétés
différemment ; les champs non universels ne sont pas forcés.

## Buffers mémoire
Le service inclut aussi la commande de vidage d'un buffer mémoire nommé
(`/system logging action clear`) pour les RouterOS qui la supportent.
