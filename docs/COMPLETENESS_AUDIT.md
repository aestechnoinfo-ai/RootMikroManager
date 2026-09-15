# RootMikroManager — Audit de complétude avant phase plateforme

## Déjà construit
- stockage multi-routeurs SQLite + secrets sécurisés ;
- connexion RouterOS API 8728 ;
- Hotspot users / profiles / active / cookies / hosts / IP binding ;
- génération vouchers + historique ;
- PPP secrets / profiles / active ;
- DHCP leases ;
- DNS static ;
- Firewall Filter / NAT ;
- Simple Queues ;
- interfaces ;
- monitoring RX/TX ;
- Wireless lecture ;
- Scripts ;
- Scheduler ;
- Logs ;
- Ping / traceroute ;
- backup RouterOS ;
- export .rsc ;
- backup/restauration JSON RootMikroManager ;
- Reports ;
- System resources / reboot / shutdown ;
- Neighbor Discovery ;
- RoMON ;
- découverte VPN-aware WireGuard / BackToHome / ZeroTier ;
- scan IP des ports API/API-SSL/Winbox ;
- audit local ;
- groupes/tags multi-routeurs ;
- paramètres applicatifs.

## Restant avant de qualifier la conversion de complète
1. API-SSL 8729 avec SecureSocket.
2. Actions Hotspot avancées :
   - disconnect active ;
   - make-binding depuis hosts ;
   - IP Binding create/edit ;
   - recherche/bulk.
3. Voucher avancé :
   - modes username/password ;
   - préfixes/longueurs ;
   - uptime/data limits ;
   - modèles imprimables/QR.
4. PPP avancé :
   - édition complète ;
   - disconnect active.
5. Firewall avancé :
   - Mangle ;
   - Address Lists ;
   - déplacement/réordonnancement.
6. Queue Tree.
7. gestion de fichiers RouterOS pour téléchargement/restauration de backups.
8. vraie couche native Android/iOS pour MNDP/LLDP direct depuis le téléphone.
9. architecture Riverpod/Clean Architecture à finaliser.
10. audit de parité détaillé avec l'ensemble des modules PHP source.

## Phase plateforme différée
- Android/iOS complet ;
- permissions réseau ;
- services natifs ;
- compileSdk/Gradle ;
- APK/release.

Cette phase reste volontairement différée jusqu'à la fin de la construction fonctionnelle.


## Fermé dans API_SSL_HOTSPOT_ADVANCED
- transport SecureSocket pour API-SSL 8729 ;
- primitives disconnect Hotspot active ;
- primitives Host -> IP Binding ;
- création IP Binding ;
- générateur vouchers avec modes, préfixes, longueurs, uptime et data limit.

## Encore à fermer
- UI Hotspot pour exposer toutes les primitives avancées ;
- impression/QR vouchers ;
- PPP edit/disconnect UI ;
- Mangle / Address Lists UI ;
- Queue Tree UI ;
- gestion des fichiers RouterOS ;
- durcissement TLS/certificats ;
- couche native MNDP/LLDP mobile ;
- migration finale Riverpod/Clean Architecture ;
- audit de parité PHP détaillé.


## Fermé dans PPP_FIREWALL_QUEUES_ADVANCED
- PPP secrets edit ;
- PPP profiles edit ;
- déconnexion PPP active ;
- Firewall Mangle ;
- Firewall Address Lists ;
- Queue Tree ;
- hubs Firewall/Queues.

## Principaux écarts restants
- UI Hotspot Host -> Binding / IP Binding create-edit / disconnect active ;
- impression/QR vouchers ;
- règles Firewall formulaires spécialisés + réordonnancement ;
- fichiers RouterOS et restauration backup ;
- durcissement TLS ;
- MNDP/LLDP mobile natif ;
- Riverpod/Clean Architecture ;
- audit de parité PHP final.


## Fermé dans HOTSPOT_FILES_PHASE
- UI disconnect Hotspot active ;
- UI Host -> IP Binding ;
- IP Binding create/edit/enable/disable/delete ;
- liste `/file` RouterOS ;
- suppression de fichiers ;
- consolidation écran Backup.

## Principaux écarts restants
- téléchargement/restauration binaire des backups RouterOS ;
- impression/QR vouchers ;
- Firewall formulaires spécialisés/réordonnancement ;
- TLS strict / certificate pinning ;
- couche native MNDP/LLDP mobile ;
- Riverpod/Clean Architecture ;
- audit final de parité PHP.


## Fermé dans VOUCHER_QR_TLS_RESTORE
- API-SSL 8729 réellement transporté par SecureSocket ;
- choix validation TLS stricte / certificat auto-signé ;
- QR vouchers ;
- prévisualisation responsive vouchers ;
- impression et génération PDF vouchers ;
- restauration d'un `.backup` déjà présent sur le routeur avec confirmation forte.

## Écarts majeurs restant
- transfert binaire backup entre téléphone et RouterOS ;
- formulaires Firewall spécialisés et réordonnancement ;
- certificate pinning / empreinte TLS ;
- découverte MNDP/LLDP native côté téléphone ;
- consolidation architecture Riverpod/Clean Architecture ;
- audit de parité PHP final et suppression des écrans legacy.


## Intégration étudiée et ajoutée : router_os_client + http
- `router_os_client ^2.0.1` ajouté ;
- adapter dédié pour tags/concurrence/streaming ;
- `http ^1.6.0` ajouté ;
- client RouterOS REST HTTPS ;
- séparation explicite socket API / REST ;
- stratégie hybride documentée ;
- aucune migration brutale du client existant.

## Impact
La prochaine refonte du monitoring peut utiliser `router_os_client.streamData`
et `cancelTagged` au lieu d'un polling artificiel quand le routeur et la
commande supportent une opération longue.


## Fermé dans STREAMING_MONITORING
- signature `streamData` corrigée selon router_os_client 2.0.1 ;
- support `port` réel du package pris en compte ;
- monitoring `/interface/monitor-traffic` en streaming ;
- tag + cancel ;
- fallback polling ;
- historique RX/TX ;
- Torch streaming ;
- session active disponible pour second socket de monitoring.

## Restant
- migration d'autres écrans live vers streams quand pertinente ;
- monitoring système consolidé ;
- transfert binaire backup ;
- MNDP/LLDP natif mobile ;
- consolidation architecture ;
- audit final de parité PHP.


## Fermé dans ROOTMIKROMANAGER_VOUCHER_PARITY
- formulaire Generate User aligné sur RootMikroManager officiel ;
- modes `up` / `vc` ;
- caractères lower/upper/upplow/mix/mix1/mix2/num ;
- longueur 3-8, quantité 1-560, préfixe 6, suffixe 6 ;
- Hotspot Server ;
- Time Limit ;
- Data Limit MB/GB ;
- commentaire RootMikroManager structuré ;
- lecture validity/price/selling price/lock depuis `on-login` ;
- Print Default / QR / Small ;
- prévention des collisions de username.


## VOUCHER_SUFFIX_PHASE
- suffixe facultatif ajouté juste sous le préfixe ;
- concaténation stricte `prefix + code + suffix`, sans séparateur automatique ;
- quantité alignée sur RootMikroManager officiel : 1 à 560 ;
- `num` limité au mode `vc`, conformément au formulaire PHP officiel ;
- aucun FloatingActionButton restant dans `lib/` au moment de cet audit.


## HOTSPOT PROFILE ROOTMIKROMANAGER PARITY
- CRUD profil Hotspot enrichi ;
- Address Pool dynamique ;
- Parent Queue non dynamique ;
- Expired Mode RootMikroManager ;
- Validity ;
- Grace Period conservé sans comportement inventé ;
- Price / Selling Price ;
- Lock User MAC ;
- on-login généré ;
- scheduler créé/mis à jour/supprimé ;
- renommage du profil synchronisé avec le scheduler ;
- suppression avec confirmation.


## HOTSPOT USERS ROOTMIKROMANAGER PARITY
- filtre profil ;
- filtre lot/comment ;
- recherche ;
- expired = limit-uptime 1s ;
- éditeur complet ;
- enable / disable ;
- reset counters + scheduler ;
- suppression expired ;
- suppression sécurisée comment + uptime 00:00:00 ;
- impression individuelle Default / QR / Small.


## REST CONNECTION FIX
- URI REST centralisée ;
- HTTPS par défaut ;
- blocage explicite HTTP:443 ;
- blocage explicite HTTPS:80 ;
- certificat auto-signé optionnel ;
- diagnostic TLS / Socket / ClientException ;
- aucun littéral http://*:443 dans le code Dart.


## HOTSPOT ADVANCED ROOTMIKROMANAGER PARITY
- Active filtré par serveur ;
- détails Active complets ;
- suppression cookie + active à la déconnexion ;
- Cookies list/remove ;
- Hosts list/remove ;
- Host -> IP Binding ;
- IP Binding Server/Type/edit/enable/disable ;
- cleanup Queue/Scheduler/ARP/DHCP Lease à la suppression.

## DHCP STATUS TRAFFIC ROOTMIKROMANAGER PARITY
- DHCP D/S + champs officiels RootMikroManager ;
- recherche et résumé DHCP ;
- test TCP du port API avec timeout 5 s ;
- compatible accès VPN routé ;
- monitor-traffic once conservé ;
- correction repaint RX/TX ;
- couleurs du graphe issues du thème.

## ROOTMIKROMANAGER SYSTEM SCHEDULER PARITY
- Scheduler fields/parity + search + enable/disable/remove ;
- avertissement Monitor Profile ;
- exécution scripts RouterOS ;
- protection comment=rootmikromanager ;
- logs recherche/topic.
