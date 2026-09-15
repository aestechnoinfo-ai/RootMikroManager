# go_router — suppression du pont `/module/:module`

## Résultat

La navigation Dashboard/Drawer n’utilise plus de module textuel intermédiaire.

Supprimés :

- `ModuleScreen` ;
- route `/module/:module` ;
- `AppRouter.pushModule()` ;
- `moduleLocation()` ;
- `AppRoutes.module` / `AppRoutePaths.module` ;
- `LegacyModuleNames`.

## Drawer et Dashboard

`AppDrawer` associe désormais chaque libellé visible à un `AppRoutes.*`
explicite. Le Dashboard appelle directement `AppRouter.pushNamed()`.

Les cartes Dashboard utilisent aussi directement les routes nommées pour
Routeurs, Système, Reports, Hotspot, PPPoE, Vouchers et Logs.

## Modules RouterOS sans connexion

Le comportement de sécurité de l’ancien pont est conservé avec
`_requireRouter()` dans `router.dart`.

Les modules nécessitant un routeur connecté affichent un écran explicite
« Aucun routeur connecté » avec un bouton « Ouvrir les routeurs ».

Routeurs, Settings et Audit restent accessibles sans connexion RouterOS.

## Contrôles

- `ModuleScreen` : supprimé ;
- `/module/:module` : supprimé ;
- `pushModule()` : 0 ;
- `pushPage()` : 0 ;
- `MaterialPageRoute` : 0 ;
- toutes les entrées du Drawer pointent vers des `GoRoute` déclarés ;
- collisions noms/paths : 0 ;
- imports relatifs manquants : 0.

Le SDK Flutter/Dart n’est pas présent dans l’environnement de cette passe ;
aucun `flutter analyze` ou build APK n’est revendiqué.
