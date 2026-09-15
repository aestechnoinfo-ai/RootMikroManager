# RootMikroManager

**RootMikroManager** est une application native **Flutter/Dart** de gestion d'équipements **MikroTik RouterOS** — hotspot, PPP/PPPoE, DHCP, firewall, files d'attente, VPN, monitoring et bien plus — directement depuis un téléphone, une tablette ou un ordinateur, sans passer par un serveur web PHP intermédiaire.

Le projet est une migration fonctionnelle de l'outil web historique *RootMikroManager* vers une application native multiplateforme (Android, Windows, Linux, macOS, iOS, Web), qui communique en direct avec l'API RouterOS des routeurs.

> ⚠️ **Statut du projet** : de nombreux modules sont fonctionnels et communiquent réellement avec l'API RouterOS, mais la parité complète avec toutes les pages de l'outil PHP d'origine est un travail en cours. Chaque module doit être validé sur un routeur MikroTik réel (RouterOS 6/7) avant un usage en production. Voir [docs/COMPLETENESS_AUDIT.md](docs/COMPLETENESS_AUDIT.md).

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Captures d'écran](#captures-décran)
- [Architecture technique](#architecture-technique)
- [Structure du projet](#structure-du-projet)
- [Démarrage rapide](#démarrage-rapide)
- [Compilation](#compilation)
- [Documentation](#documentation)
- [Avertissement](#avertissement)

## Fonctionnalités

### Connexion & gestion multi-routeurs
- Ajout, groupes, tags et recherche multi-routeurs.
- Connexion via API RouterOS (port 8728) et API-SSL (port 8729, `SecureSocket`, certificat auto-signé ou validation stricte), ainsi que REST HTTPS.
- Découverte réseau : scan IP `/24`, Neighbor Discovery, RoMON.
- Découverte via VPN (WireGuard, MikroTik BackToHome, ZeroTier) avec extraction automatique des plages candidates.
- Mot de passe stocké dans le stockage sécurisé de l'appareil (`flutter_secure_storage`).

### Hotspot
- Liste des utilisateurs et sessions actives, déconnexion.
- Générateur de vouchers (préfixe, longueur, mode, durée, limite de données) avec écriture RouterOS et historique local SQLite, impression et export QR/PDF.
- Profils Hotspot complets (Pool, Shared Users, Rate Limit, Expired Mode, Validity, Grace Period, Price, Selling Price, Lock User, Parent Queue) avec génération du script *on-login* et synchronisation du scheduler.
- Host → IP Binding, filtres profil/lot/expiration, réinitialisation et suppression sécurisée par lot.

### Réseau & routage
- DHCP (baux et serveurs), DNS statique, Interfaces, Wireless/CAPsMAN, Bridge/VLAN.
- Firewall Filter/NAT/Mangle/Address Lists, Simple Queues et Queue Tree — CRUD complet.
- PPP/PPPoE (secrets, profils, sessions actives), routage IP et IPv6.
- Outils réseau : Ping, Traceroute, test TCP du port API.

### Monitoring & système
- Traffic RX/TX en direct via `router_os_client` (`/interface/monitor-traffic` en streaming, avec repli en polling) et Torch temps réel.
- Logs, Scripts, Scheduler RouterOS consultables et exécutables.
- Rapports de vente (Selling Report) avec filtres, recherche, export CSV.
- Sauvegarde/restauration : backup RouterOS natif, export/import JSON local, gestionnaire de fichiers du routeur.
- Commandes système (reboot, shutdown) avec confirmation utilisateur.
- Journal d'audit local des actions effectuées.

## Captures d'écran

<!-- SCREENSHOTS -->

## Architecture technique

- **UI** : Flutter, navigation via `go_router`.
- **Données locales** : SQLite (`sqflite`), avec migrations versionnées et export/import JSON.
- **Secrets** : `flutter_secure_storage`.
- **RouterOS** : client API binaire maison (`lib/core/routeros`) + `router_os_client` pour le streaming, `http` pour le REST HTTPS.
- Aucun serveur PHP ou web intermédiaire n'est nécessaire : l'application dialogue directement avec l'API du routeur.

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) et [docs/MIGRATION_MAPPING.md](docs/MIGRATION_MAPPING.md) pour le détail de la correspondance avec l'outil PHP d'origine.

## Structure du projet

```
lib/
  core/           # RouterOS client/API, base de données, sécurité, navigation, réseau
  features/       # Un dossier par module : hotspot, ppp, firewall, queues, vouchers,
                  # monitoring, discovery, vpn, reports, system, audit, backup, ...
docs/             # Journal détaillé de chaque phase de développement (un fichier par lot)
android/ ios/ linux/ macos/ windows/ web/   # Cibles de compilation Flutter
```

## Démarrage rapide

Prérequis : [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ≥ 3.12) et, selon la cible, Android SDK / Xcode / toolchain desktop.

```bash
flutter pub get
flutter analyze
flutter run
```

Puis dans l'application : ajouter un routeur → tester la connexion API → accéder aux modules (bloqués tant qu'aucun routeur n'est connecté).

## Compilation

```bash
# Android (APK release)
./BUILD_ROOTMIKROMANAGER.ps1
# ou manuellement :
flutter build apk --release
```

Voir [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md) et [android/README_ANDROID_BUILD.md](android/README_ANDROID_BUILD.md) pour le détail par plateforme.

## Documentation

L'historique complet des lots de développement (un module ou une correction par fichier) est disponible dans [docs/](docs/). Points d'entrée utiles :

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — architecture générale.
- [docs/MIGRATION_MAPPING.md](docs/MIGRATION_MAPPING.md) — correspondance avec les pages PHP d'origine.
- [docs/COMPLETENESS_AUDIT.md](docs/COMPLETENESS_AUDIT.md) — écarts fonctionnels restants.
- [docs/PHP_SOURCE_INVENTORY.md](docs/PHP_SOURCE_INVENTORY.md) — inventaire de la base historique.

## Avertissement

Cette application exécute des commandes réelles sur des équipements RouterOS (y compris des opérations destructrices : suppression d'utilisateurs, redémarrage, modification du firewall, etc.). Testez systématiquement sur un routeur de test avant toute utilisation en production, et assurez-vous que le compte MikroTik utilisé dispose des droits appropriés.
