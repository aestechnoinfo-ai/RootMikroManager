# go_router — premier lot de fichiers à migrer

## Baseline après activation de la coque

- `MaterialApp.router` : actif.
- Route `/` : `DashboardScreen`.
- Pont `routes de domaine explicites` : `ancien écran-pont supprimé`.
- `MaterialPageRoute` restant : 136 occurrences dans 93 fichiers.
- Les navigations impératives existantes restent temporairement compatibles.

## Lot 1 recommandé — branche gestionnaire et points d'entrée

### 1. `lib/features/dashboard/dashboard_screen.dart`
- 1 `MaterialPageRoute`.
- Priorité maximale.
- Remplacer `_open(String module)` par la route nommée `module`.
- Le Drawer et les cartes Dashboard bénéficieront immédiatement du pont
  `routes de domaine explicites`.

### 2. `lib/features/hotspot/hotspot_management_screen.dart`
- 2 `MaterialPageRoute`.
- Contient au moins un retour typé `Navigator.push<bool>`.
- Migrer avec `context.pushNamed<bool>()` pour conserver le rechargement après
  édition.

### 3. `lib/features/hotspot/hotspot_users_screen.dart`
- 5 `MaterialPageRoute`.
- 2 navigations avec retour typé `bool`.
- À migrer juste après l'écran Hotspot principal.

### 4. `lib/features/vouchers/voucher_generator_screen.dart`
- 4 `MaterialPageRoute`.
- Point d'entrée principal vouchers.
- Créer des routes dédiées pour historique, impression, résultat de génération
  et hub avancé.

### 5. `lib/features/vouchers/voucher_operations_hub_screen.dart`
- 1 `MaterialPageRoute` générique servant à ouvrir de nombreux écrans.
- Ne pas remplacer par une route dynamique arbitraire.
- Déclarer des routes nommées pour les écrans du hub au fur et à mesure.

### 6. `lib/features/ppp/ppp_management_screen.dart`
- 3 `MaterialPageRoute`.
- Contient au moins un retour typé `bool`.
- Préserver les retours d'édition via `context.pushNamed<bool>()`.

### 7. `lib/features/ppp/ppp_hub_screen.dart`
- 1 `MaterialPageRoute` générique.
- Comme pour vouchers, convertir les destinations du hub en routes nommées.

### 8. `lib/features/reports/reports_screen.dart`
- 20 `MaterialPageRoute`.
- Plus grosse concentration du projet.
- À traiter après les points d'entrée Hotspot/Vouchers/PPP afin de ne pas
  introduire 20 routes avant d'avoir stabilisé notre convention.

### 9. `lib/features/reports/report_export_hub_screen.dart`
- 1 `MaterialPageRoute` générique.
- À migrer dans la même passe que `reports_screen.dart`.

## Ordre de travail proposé

### Phase A — coque + pont
1. `dashboard_screen.dart`
2. vérifier Drawer et cartes Dashboard via `routes de domaine explicites`

### Phase B — Hotspot
3. `hotspot_management_screen.dart`
4. `hotspot_users_screen.dart`

### Phase C — Vouchers
5. `voucher_generator_screen.dart`
6. `voucher_operations_hub_screen.dart`

### Phase D — PPP
7. `ppp_management_screen.dart`
8. `ppp_hub_screen.dart`

### Phase E — Reports
9. `reports_screen.dart`
10. `report_export_hub_screen.dart`

Le premier lot réel représente 39 occurrences de `MaterialPageRoute` dans
9 fichiers. Après conversion complète de ce lot, le projet devrait passer
de 136 à environ 97 occurrences, sous réserve qu'aucune nouvelle navigation
impérative ne soit ajoutée pendant la passe.

## Convention à appliquer pendant la migration

- `context.goNamed(...)` : changement de destination racine sans résultat.
- `context.pushNamed(...)` : empiler un écran et permettre le retour.
- `context.pushNamed<T>(...)` : écran qui doit retourner une valeur.
- `context.pop(result)` : retourner une valeur à l'appelant.
- identifiants stables : path/query seulement si non sensibles ;
- mot de passe RouterOS : jamais dans l'URL ;
- `RouterOsService` : récupéré depuis la session existante quand possible,
  plutôt que transporté dans une URL.
