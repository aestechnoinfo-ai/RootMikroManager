# Routing Policy & IPv6 — sécurité et configuration

Ce lot ajoute :
- Routing Rules complètes : source, destination, interface, action, table, commentaire, enabled ;
- activation/désactivation et suppression confirmée des rules ;
- suppression sûre des tables, bloquée si règles/routes les référencent ;
- CRUD des adresses IPv6 statiques avec advertise/eui-64 ;
- CRUD des routes IPv6 statiques via `/ipv6/route` ;
- vue Neighbor Discovery `/ipv6/nd` avec activation/désactivation prudente ;
- audit des tables absentes, rules globales dangereuses, tables vides, route ::/0 et SLAAC non /64.

Rappels :
- une table personnalisée doit être créée dans `/routing/table` avant utilisation ;
- `lookup-only-in-table` ne retombe pas vers `main` ;
- `/routing/route` est une vue étendue en lecture seule ; les routes IPv6 s’écrivent via `/ipv6/route`.
