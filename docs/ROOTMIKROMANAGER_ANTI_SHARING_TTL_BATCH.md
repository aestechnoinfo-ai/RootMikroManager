# Anti-partage Internet par Mangle TTL

RootMikroManager peut créer une règle dédiée par interface :

- `/ip/firewall/mangle`
- `chain=postrouting`
- `out-interface=<interface>`
- `action=change-ttl`
- `new-ttl=set:1`
- `passthrough=yes`

Le TTL reste configurable de 1 à 255.

Les règles créées par cette fonction portent un commentaire commençant par
`RootMikroManager AntiSharing`. La liste dédiée ne manipule que ces règles.

Fonctions :
- choisir une interface ;
- créer/mettre à jour la protection ;
- lister les interfaces protégées ;
- activer/désactiver chaque règle ;
- modifier le TTL ;
- supprimer la règle ;
- résumé actifs/suspendus.

Le module Mangle conserve parallèlement l'accès aux règles Mangle ordinaires.
