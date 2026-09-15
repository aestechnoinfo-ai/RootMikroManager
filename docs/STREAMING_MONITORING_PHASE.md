# RootMikroManager - Streaming Monitoring

## Vérification router_os_client 2.0.1

La documentation actuelle confirme :

- constructeur avec `address`, `user`, `password`, `useSsl`, `port`,
  `SecurityContext` et `timeout`;
- `streamData(...) -> Stream<Map<String, String>>`;
- `talkTagged(...)`;
- `talkMultiple(...)`;
- `cancelTagged(...)`;
- `isAlive() -> Future<bool>`.

L'adapter précédent avait une signature incorrecte pour `streamData`.
Elle est corrigée dans cette phase.

## Traffic interfaces

`/interface/monitor-traffic` fonctionne maintenant en streaming via
`router_os_client`.

RootMikroManager :
1. ouvre un socket de monitoring distinct ;
2. utilise un tag explicite ;
3. reçoit les valeurs au fil de l'eau ;
4. annule proprement le stream ;
5. retombe sur le polling interne toutes les 2 secondes si le streaming
   échoue.

Cela évite de casser les routeurs utilisant une configuration TLS non
compatible avec le package.

## Historique graphique

Le monitoring conserve les 60 derniers échantillons RX/TX et les affiche
avec un `CustomPainter`, sans ajouter une bibliothèque graphique.

## Torch

Un écran Torch en temps réel a été ajouté avec :
- interface ;
- source address ;
- destination address ;
- protocol ;
- port ;
- start/stop ;
- tag/cancel ;
- maximum 200 résultats en mémoire.

Torch est un outil de diagnostic réel de RouterOS et peut nécessiter la
policy `sniff` selon les droits RouterOS utilisés.

## Session

Les identifiants de la connexion active sont conservés temporairement en
mémoire afin d'ouvrir le second socket de streaming.
Ils ne remplacent pas la persistance sécurisée via `flutter_secure_storage`.
