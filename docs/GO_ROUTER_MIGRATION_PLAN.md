# Plan de migration vers go_router

## État initial

- Navigation active : `MaterialApp`, `Navigator.push`, `MaterialPageRoute`.
- Baseline au moment de cette préparation : 136 occurrences de `MaterialPageRoute`
  réparties dans 93 fichiers.
- `routes.dart` et `router.dart` résident dans `lib/core/navigation/`.
- `go_router` est déclaré dans `pubspec.yaml`.
- La coque externe est désormais active via `MaterialApp.router`.
- `DashboardScreen` est la route `/`.
- `ancien écran-pont supprimé` reste le pont temporaire `routes de domaine explicites`.
- Les anciennes navigations internes restent en place pendant la migration progressive.

## Principe

Migrer progressivement sans casser la navigation existante. Chaque phase doit
laisser l'application fonctionnelle et réversible. On ne remplace jamais les
136 appels en une seule passe.

## Étape 0 — Préparation [FAITE]

1. Ajouter `go_router`.
2. Centraliser les noms et chemins dans `routes.dart`.
3. Préparer un `GoRouter` dormant dans `router.dart`.
4. Garder `MaterialApp` et `DashboardScreen` inchangés.
5. Mesurer les usages `MaterialPageRoute`.

Critère de sortie : aucun comportement de navigation n'a changé.

## Étape 1 — Normaliser les destinations

1. Recenser tous les titres utilisés par `ancien écran-pont supprimé`.
2. Ajouter une constante dans `routes.dart` pour chaque destination stable.
3. Éliminer progressivement les chaînes de navigation dispersées.
4. Ne pas encore remplacer `Navigator.push`.

Priorité :
- Dashboard
- Routeurs
- Settings
- Audit
- Hotspot
- Vouchers
- PPP
- Reports

Critère : toutes les destinations principales ont un nom et un chemin uniques.

## Étape 2 — Activer go_router uniquement à la racine [FAITE]

1. Remplacer `MaterialApp(...)` par `MaterialApp.router(...)` dans `app.dart`. ✅
2. Instancier `PreparedAppRouter.build()`. ✅
3. Conserver le reste des `MaterialPageRoute`. ✅
4. Vérifier retour Android, bouton Back, Drawer et Dashboard.
5. Aucun écran métier n'est encore migré.

Rollback : remettre l'ancien `MaterialApp`.

## Étape 3 — Migrer Dashboard et Drawer

Remplacer :
`Navigator.push(... ancien écran-pont supprimé(title: module))`

par une navigation nommée ou une location go_router vers `routes de domaine explicites`.

Le `ancien écran-pont supprimé` reste temporairement le pont entre ancien et nouveau système.

Critère :
- Dashboard et Drawer n'utilisent plus `MaterialPageRoute`.
- Les modules continuent à fonctionner sans modification interne.

## Étape 4 — Migrer la branche gestionnaire

Ordre conseillé :
1. Hotspot
2. Vouchers
3. PPP
4. Reports
5. Backup / Audit / Settings

Pour chaque écran :
1. créer la route ;
2. définir ses paramètres de chemin/query ;
3. éviter `extra` pour les identifiants persistants ;
4. conserver `extra` uniquement pour des objets éphémères impossibles à
   reconstruire ;
5. remplacer un seul groupe de `MaterialPageRoute` ;
6. vérifier le retour et les résultats renvoyés par les écrans ;
7. seulement ensuite migrer le groupe suivant.

Important : les écrans qui attendent un résultat `bool` après
`Navigator.push<bool>` nécessitent une migration vers `context.push<T>()` et
doivent être testés séparément.

## Étape 5 — Introduire les routes imbriquées

Quand les écrans principaux sont stables :
- `/hotspot/users`
- `/hotspot/profiles`
- `/hotspot/active`
- `/vouchers/generate`
- `/vouchers/history`
- `/vouchers/print`
- `/ppp/secrets`
- `/ppp/profiles`
- `/ppp/active`
- `/reports/sales`
- `/reports/user-log`
- `/reports/monthly`

But : supprimer progressivement le rôle de routeur central de `ancien écran-pont supprimé`.

## Étape 6 — Migrer la partie administration avancée

Après la branche gestionnaire :
- Interfaces
- DHCP
- DNS
- Bridge/VLAN
- Routing
- Firewall/NAT/Mangle
- Queues
- Wireless
- VPN
- Discovery / Neighbor / RoMON
- Tools
- System

Créer les routes par domaine, pas écran par écran sans structure.

## Étape 7 — Shell / navigation persistante

Seulement si l'UI finale en a besoin :
- `ShellRoute` pour une structure persistante ;
- `StatefulShellRoute` seulement si plusieurs branches doivent conserver leur
  propre pile de navigation.

Ne pas introduire un Shell tant que les destinations principales ne sont pas
stables.

## Étape 8 — Redirections et état de connexion

Ajouter ensuite les règles :
- routeur non connecté ;
- route nécessitant une session RouterOS ;
- retour vers la liste des routeurs ;
- éventuelles routes publiques/locales.

Les redirections ne doivent pas contenir de logique métier RouterOS lourde.

## Étape 9 — Supprimer le pont legacy

Quand toutes les destinations de `ancien écran-pont supprimé` ont leur route :
1. supprimer les navigations basées sur le titre ;
2. réduire puis supprimer `ancien écran-pont supprimé` comme routeur interne ;
3. interdire les nouvelles `MaterialPageRoute` ;
4. lancer un audit global.

Critère :
`MaterialPageRoute` = 0 dans `lib/`, hors cas explicitement documenté.

## Étape 10 — Nettoyage final

- retirer les constantes legacy inutilisées ;
- ajouter tests de navigation ;
- tester deep links ;
- tester Back Android/iOS ;
- tester restauration après redémarrage ;
- vérifier qu'aucune route ne transporte de mot de passe ou secret dans l'URL ;
- documenter la carte finale des routes.

## Règles de migration

- Jamais de mot de passe RouterOS dans `pathParameters` ou `queryParameters`.
- Les identifiants stables vont dans l'URL ; les secrets restent dans
  `flutter_secure_storage` / session.
- Utiliser des noms de routes constants.
- Préférer `context.pushNamed<T>()` lorsqu'un résultat est attendu.
- Préférer `context.goNamed()` pour changer de destination sans attendre de
  résultat.
- Migrer par domaine fonctionnel et non par remplacement global automatique.
- Garder la possibilité de rollback pendant chaque phase.
