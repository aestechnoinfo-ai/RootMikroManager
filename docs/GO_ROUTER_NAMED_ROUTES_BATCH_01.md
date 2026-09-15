# go_router — routes nommées finales, lot 01

## Objectif

Commencer la seconde phase de migration : remplacer le pont générique
`PreparedAppRouter.pushPage<T>()` par de vraies routes nommées.

## Routes de domaine désormais actives

- `/hotspot` → Hotspot
- `/vouchers` → génération de vouchers
- `/ppp` → hub PPP
- `/reports` → rapports

`PreparedAppRouter.pushModule()` envoie désormais directement ces quatre
modules vers leur route nommée. Les autres modules continuent temporairement
via `routes de domaine explicites`.

## Arborescence Reports déclarée

- `/reports/live`
- `/reports/sales`
- `/reports/user-log`
- `/reports/monthly`
- `/reports/sales-by-profile`
- `/reports/sales-integrity`
- `/reports/sales-duplicates`
- `/reports/sales-date-range`
- `/reports/sales-ledger`
- `/reports/sales-consistency`
- `/reports/exports`
- `/reports/sales-unique-revenue`
- `/reports/sales-retention`
- `/reports/sales-data-quality`
- `/reports/management-readiness`
- `/reports/manager-freeze`
- `/reports/static-audit`
- `/reports/validation-matrix`
- `/reports/sales-cleanup`
- `/vouchers/history`

Les 20 appels du `ReportsScreen` n'utilisent plus le pont générique.

## Autres routes nommées ajoutées

- `/hotspot/settings`
- `/vouchers/operations`
- `/ppp/active`
- `/ppp/export`

## Sécurité de navigation

Le `RouterOsService` est récupéré depuis `RouterSession.instance`.
Aucun mot de passe RouterOS ou secret n'est placé dans les chemins ou
paramètres URL.

Les éditeurs et écrans qui transportent encore des objets complexes restent
temporairement sur `pushPage<T>()`. Ils seront migrés avec des payloads typés
ou des identifiants stables lors des lots suivants.
