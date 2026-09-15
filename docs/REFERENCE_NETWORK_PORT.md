# Adaptation de la découverte et des connexions — 4 septembre 2026

Référence lue, non modifiée : `C:/Users/pro/Documents/dev claude/roothotspot_app`.
Fichiers étudiés : `mndp_scanner.dart`, `router_connection_pool.dart`,
`routeros_api_client.dart`, `router_repository.dart`, `add_router_screen.dart`.

## Mécanismes repris

- Socket UDP IPv4 5678 direct, broadcast immédiat puis toutes les 3 secondes.
- Adresse source du datagramme utilisée pour ajouter le voisin, même si le
  routeur annonce une autre adresse d'interface. Identité facultative, UTF-8
  et Latin-1 acceptés. Paquets tronqués rejetés, dédoublonnage par MAC.
- Scan de 15 secondes indépendant du timeout TCP, fermeture lors d'annulation
  ou sélection d'un voisin. Aucun scan automatique au démarrage de l'app.
- Ping TCP et connexion API empruntent le routage système via Dart Socket.
  Suppression de la sélection VPN implicite du ping uniquement.
- Ajout manuel et découverte utilisent le formulaire de validation API.
  Modification des identifiants testée avant écriture locale.
- Réutilisation de la session authentifiée ; réouverture à la prochaine commande
  si le socket est fermé, une seule authentification pour les appels concurrents.
- Commandes sérialisées ; une opération déjà envoyée et échouée n'est jamais
  rejouée automatiquement. Déconnexion explicite et changement de session
  invalident les opérations en attente. Erreur d'authentification arrête les essais.

## Adaptations conservées

SQLite, stockage sécurisé, routes go_router et modèle de session active restent
ceux de RootMikroManager. Pas de migration vers Riverpod/Drift ni de copie de
l'interface du projet de référence. Pas de pool multi-routeurs : une session
active partagée par tous les écrans existants. Heartbeat de 30 secondes conservé
comme contrôle secondaire, sans boucle de reconnexion retardant le changement
de routeur. API binaire existante conservée avec gestion renforcée des coupures
d'écriture. Les dépendances demandées restent installées ; le scan local suit
désormais le transport et le décodage direct du projet de référence, pas le
listener du package mikrotik_mndp ni l'ancien EventChannel Android.

L'ouverture continue d'exiger le bouton Pinger réussi avant Connecter, puis
bascule vers le dashboard. TLS strict par défaut ; acceptation d'un certificat
auto-signé uniquement via le choix explicite déjà présent dans l'écran.

## Limites et vérification

Les tests utilisent des paquets synthétiques et un serveur TCP loopback, jamais
des MikroTik réels. MNDP est local au segment réseau et ne traverse pas un VPN
routé. RoMON reste une découverte via un routeur connecté, pas un transport API
MAC ni un tunnel RoMON. La validation sur téléphone/LAN reste à effectuer avec
l'accord de l'utilisateur ; aucune fiabilité matérielle absolue n'est présumée.

Vérifications locales : `flutter test --no-pub` — 50 tests réussis ; analyse
statique ciblée des 11 fichiers Dart modifiés/ajoutés — aucun problème signalé.
