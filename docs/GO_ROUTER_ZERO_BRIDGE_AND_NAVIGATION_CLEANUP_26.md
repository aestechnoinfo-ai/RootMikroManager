# go_router — suppression du pont temporaire et nettoyage navigation

## Résultat principal

Cette passe termine la migration du pont impératif :

- `PreparedAppRouter.pushPage()` : supprimé ;
- `migrationPage` : supprimé ;
- `MaterialPageRoute` : 0 ;
- les 25 derniers appels ont été convertis vers des routes nommées ;
- `PreparedAppRouter` a été renommé en `AppRouter`.

## Navigation finale

Les fichiers sont maintenant directement sous :

- `lib/core/navigation/router.dart`
- `lib/core/navigation/routes.dart`
- `lib/core/navigation/navigation_payloads.dart`

Le dossier L’ancien sous-dossier préparatoire de navigation n’existe plus.

## Hubs

Les hubs Firewall, Interfaces, Routing Policy, VPN avancé, Wi-Fi,
Wireless, PPP, Queues, Automation, Logging, System, Security, Tools et
Voucher Operations utilisent désormais des routes explicites.

Les routes des destinations de hubs sont déclarées individuellement dans
`routes.dart` et construites dans `router.dart`. Aucun nouveau pont générique
de type `Widget` dans `GoRouterState.extra` n’a été introduit.

## Flux directs finalisés

Les derniers flux directs incluent :

- Scheduler editor ;
- Wi-Fi provisioning ;
- résultat de nettoyage de lots vouchers ;
- impression / réimpression vouchers ;
- aperçu du template voucher ;
- détail ticket Hotspot ;
- édition peer WireGuard.

Les objets métier complexes restent transportés en mémoire via des payloads
typés. Les mots de passe et secrets ne sont pas placés dans les URL.

## Contrôles statiques

- `pushPage` : 0
- `migrationPage` : 0
- anciennes références au sous-dossier préparatoire de navigation : 0
- anciennes références `PreparedAppRouter` : 0
- collisions noms de routes : 0
- collisions chemins de routes : 0
- imports relatifs manquants : 0
- ancienne marque dans le projet : 0
- `FloatingActionButton` : 0
- délimiteurs des fichiers modifiés : OK

Le SDK Flutter/Dart n’est pas disponible dans l’environnement d’exécution de
cette passe ; aucun `flutter analyze` ni build APK n’est donc revendiqué.
