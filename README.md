# RootMikroManager
Application Flutter/Dart native de gestion MikroTik RouterOS, issue d'une migration fonctionnelle progressive de RootMikroManager.

## État de cette livraison
Cette version renforce la base précédente avec :
- protocole binaire RouterOS amélioré, connexion et authentification API ;
- commandes RouterOS pour ressources, interfaces, logs, Hotspot et DHCP ;
- gestion Hotspot (liste, actifs, suppression) ;
- générateur de vouchers avec écriture RouterOS + historique SQLite ;
- SQLite v2 avec journaux et export JSON.

## Important
La parité totale avec toutes les pages PHP de RootMikroManager reste un travail de migration et de test module par module. Cette archive contient une base réellement implémentée pour les modules ci-dessus et doit être testée contre RouterOS 6/7 avant usage en production.

## NEXT – Modules réseau ajoutés
Cette livraison ajoute des écrans Flutter reliés au service RouterOS pour DHCP, DNS statique, Interfaces, Wireless, Firewall Filter/NAT, Simple Queues et un outil Ping. Ces modules lisent les données directement via l'API RouterOS lorsque la session est connectée.

### Limite actuelle
Les commandes d'écriture avancées (ajout/modification/suppression) doivent encore être testées sur un routeur réel avant une utilisation de production. Le protocole RouterOS peut varier selon la version et la configuration TLS/API du routeur.

## Version NEXT SYSTEM
Ajouts : Traffic avec actualisation automatique, consultation RouterOS des Scripts/Scheduler/Logs et export de sauvegarde locale JSON.

## Version MANAGEMENT
Cette version ajoute une couche CRUD RouterOS générique pour les modules DHCP, DNS et Simple Queues : ajout, modification, suppression, activation et désactivation. Les opérations sont envoyées directement au routeur connecté via l'API RouterOS.

## Version ADVANCED
Cette version ajoute la gestion CRUD Firewall Filter/NAT, la gestion des Scripts et Scheduler, ainsi qu'une base complète d'import/export JSON des données locales RootMikroManager.


## Version PRO – Suite

Ajouts: gestion Hotspot avancée (profils et comptes), consultation PPP/PPPoE, rapports synthétiques RouterOS, et commandes de création de backup/export RouterOS. Les backups RouterOS sont créés sur le routeur et doivent être récupérés via un mécanisme de téléchargement approprié selon la politique d'accès du routeur.


## Version ULTIMATE – Suite

Ajouts de cette étape :
- Outils réseau Ping et Traceroute.
- Monitoring automatique des interfaces avec actualisation périodique.
- Commandes système avec confirmation utilisateur : reboot et shutdown.
- Architecture préparée pour intégrer ces écrans à la navigation principale.

### Notes
Les commandes système et outils réseau nécessitent une connexion RouterOS active et des droits suffisants sur le compte MikroTik.


## RELEASE CANDIDATE – Consolidation

Cette version consolide les livraisons précédentes :
- correction de la couche RouterOS API pour éviter les signatures de méthodes dupliquées ;
- ajout d'une méthode `print()` cohérente avec les arguments RouterOS ;
- uniformisation des commandes CRUD ;
- correction des chemins RouterOS (`/chemin/add`, `/chemin/set`, `/chemin/remove`) ;
- suppression des extensions concurrentes qui empêchaient la compilation ;
- renommage du dossier racine en `RootMikroManager`.

### Vérification recommandée
Avant une publication APK, exécuter :
`flutter pub get`
`flutter analyze`
`flutter run`

Puis tester chaque module sur un vrai routeur MikroTik.


## STABLE – Connexion et navigation

Cette étape rend le flux d'utilisation plus cohérent :

1. Ajouter un routeur.
2. Sélectionner le routeur.
3. Tester la connexion avec l'API RouterOS.
4. Sauvegarder le mot de passe dans le stockage sécurisé.
5. Accéder aux modules qui utilisent la session RouterOS active.

La navigation bloque désormais les modules réseau lorsqu'aucun routeur n'est connecté, au lieu de provoquer des erreurs d'exécution.


## BUILD READY – Consolidation

Cette livraison prépare le projet pour la vérification réelle sur une machine Flutter :

- dépendances inutilisées retirées pour réduire les conflits ;
- documentation Android ajoutée ;
- permissions réseau documentées ;
- checklist de compilation ajoutée ;
- flux Routeur → Connexion → Session → Modules conservé.

### Important
Cette archive n'a pas été compilée automatiquement dans l'environnement de préparation, car le SDK Flutter/Android n'y est pas disponible. Le statut « BUILD READY » signifie que le projet a été consolidé pour la prochaine étape : compilation réelle avec `flutter analyze` puis `flutter run` sur votre environnement.


## INTEGRATED – Suite

Cette version corrige des incohérences d'intégration détectées entre les modules :

- le générateur de vouchers reçoit maintenant correctement le service RouterOS ;
- Firewall et NAT utilisent leurs constructeurs réels ;
- la navigation centrale utilise une correspondance explicite des modules ;
- les erreurs de génération de vouchers sont affichées proprement ;
- un document `VERIFICATION_STATUS.md` indique précisément la différence entre les corrections statiques et une compilation Flutter réelle.

### Étape suivante
La validation définitive doit être faite avec `flutter analyze` et `flutter run` sur un PC disposant du SDK Flutter/Android.


## VALIDATION BUILD

Cette version ajoute :
- script PowerShell de validation Flutter ;
- script de génération APK Release ;
- plan de tests MikroTik ;
- procédure de compilation réelle ;
- test Flutter minimal.

La compilation APK doit être effectuée dans un environnement disposant de Flutter,
Gradle et du SDK Android.


## BUSINESS MODULES PHASE

Cette phase étend la construction fonctionnelle :
- Vouchers liés aux profils Hotspot réels ;
- PPP/PPPoE avec secrets, profils et actifs ;
- DHCP CRUD de base ;
- DNS statique CRUD de base ;
- Simple Queues CRUD de base ;
- RouterOS service enrichi.

Voir `docs/BUSINESS_MODULES_PHASE.md`.


## SYSTEM MONITORING PHASE

Ajouts :
- Firewall/NAT renforcé ;
- Interfaces/Traffic consolidés ;
- Scripts/Scheduler/Logs ;
- écran Système enrichi ;
- Reports synthétiques.

Voir `docs/SYSTEM_MONITORING_PHASE.md`.


## ADVANCED NETWORK PHASE

Cette phase ajoute :
- monitoring RX/TX RouterOS réel ;
- Neighbor Discovery ;
- RoMON ;
- sauvegarde JSON de l'application ;
- backup/export RouterOS ;
- entrée Voisinage dans la navigation.

Voir `docs/ADVANCED_NETWORK_PHASE.md`.


## MANAGEMENT & AUDIT PHASE

Cette phase ajoute :
- groupes/tags/recherche multi-routeurs ;
- scan IP /24 des ports MikroTik ;
- journal d’audit local ;
- restauration JSON ;
- migration SQLite v4.

Voir `docs/MANAGEMENT_AUDIT_PHASE.md`.


## VPN-AWARE DISCOVERY

Le voisinage tient maintenant compte des routeurs accessibles via
WireGuard, MikroTik BackToHome et ZeroTier :
- inspection des interfaces et peers VPN RouterOS ;
- extraction de plages VPN candidates ;
- scan CIDR des ports MikroTik 8728/8729/8291 ;
- Neighbor Discovery via le MikroTik distant ;
- RoMON via un MikroTik joignable comme point d’entrée ;
- scan CIDR VPN manuel.

Voir `docs/VPN_AWARE_DISCOVERY.md`.


## COMPLETION PHASE

Ajouts :
- historique vouchers ;
- paramètres persistants ;
- audit de complétude détaillé.

Voir `docs/COMPLETENESS_AUDIT.md` pour les écarts fonctionnels restant à fermer avant la phase Android/iOS/APK.


## API-SSL & HOTSPOT ADVANCED

Ajouts :
- RouterOS API-SSL 8729 via SecureSocket ;
- primitives Hotspot avancées ;
- vouchers avancés (préfixe, modes, longueurs, uptime, data limit, progression).

Voir `docs/API_SSL_HOTSPOT_ADVANCED.md`.


## PPP / FIREWALL / QUEUES ADVANCED

Ajouts :
- PPP/PPPoE edit + déconnexion active ;
- Firewall hub Filter/NAT/Mangle/Address Lists ;
- Queue Tree CRUD ;
- hub Queues.

Voir `docs/PPP_FIREWALL_QUEUES_ADVANCED.md`.


## HOTSPOT ADVANCED & ROUTEROS FILES

Ajouts :
- Hotspot active disconnect ;
- Host -> IP Binding ;
- IP Binding CRUD ;
- fichiers RouterOS ;
- Backup unifié.

Voir `docs/HOTSPOT_FILES_PHASE.md`.


## VOUCHER QR / TLS / RESTORE

- API-SSL 8729 réellement en `SecureSocket`;
- choix certificat auto-signé ou validation stricte;
- vouchers QR;
- impression/PDF;
- restauration d'un backup déjà présent sur RouterOS.

Voir `docs/VOUCHER_QR_TLS_RESTORE.md`.


## ROUTEROS CLIENT + HTTP

RootMikroManager intègre maintenant :
- `router_os_client ^2.0.1` comme transport socket complémentaire ;
- `http ^1.6.0` pour RouterOS REST HTTPS ;
- une stratégie hybride documentée.

Voir `docs/ROUTER_OS_CLIENT_HTTP_INTEGRATION.md`.


## STREAMING MONITORING

- `router_os_client` réellement utilisé pour le monitoring live ;
- `/interface/monitor-traffic` en streaming ;
- Torch temps réel ;
- tags + cancel ;
- fallback polling ;
- historique RX/TX responsive.

Voir `docs/STREAMING_MONITORING_PHASE.md`.


## HOTSPOT PROFILE ROOTMIKROMANAGER PARITY

Les profils Hotspot disposent maintenant du formulaire RootMikroManager complet :
Pool, Shared Users, Rate Limit, Expired Mode, Validity, Grace Period,
Price, Selling Price, Lock User et Parent Queue, avec génération du on-login
et synchronisation du scheduler associé.

Voir `docs/HOTSPOT_PROFILE_ROOTMIKROMANAGER_PARITY.md`.


## HOTSPOT USERS ROOTMIKROMANAGER PARITY

Gestion avancée des users/vouchers existants : filtres profil/lot/expired,
édition complète, enable/disable, Reset RootMikroManager, suppression sécurisée par
lot et réimpression individuelle.

Voir `docs/HOTSPOT_USERS_ROOTMIKROMANAGER_PARITY.md`.


## REST CONNECTION FIX

Le client REST empêche désormais les couples protocole/port incohérents
comme `http://router:443/rest/...`, gère HTTPS/self-signed et fournit des
erreurs réseau/TLS plus explicites.

Voir `docs/REST_CONNECTION_FIX.md`.

## DHCP / STATUS / TRAFFIC ROOTMIKROMANAGER PARITY
DHCP Leases suit la vue RootMikroManager v7.135, le test TCP du port API reproduit
le « Ping Test » RootMikroManager et le repaint RX/TX du monitoring est corrigé.

## ROOTMIKROMANAGER SELLING REPORT PARITY
Selling Report RouterOS compatible RootMikroManager : filtres Tout/Jour/Mois, recherche, total, résumé profil, CSV et Remove Data protégé.

## ROOTMIKROMANAGER SYSTEM SCHEDULER PARITY
Scheduler conforme à RootMikroManager, scripts RouterOS exécutables, Selling Report protégé et logs filtrables.
