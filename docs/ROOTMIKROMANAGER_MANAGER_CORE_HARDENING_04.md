# Gestionnaire — consolidation 04

Cette passe reste centrée sur Hotspot, vouchers, ventes, rapports, impression et PPP.

## Vouchers / Hotspot
- rapprochement historique local ↔ ventes RouterOS par username ;
- détection des vouchers présents d’un seul côté et des écarts de prix ;
- synthèse du cycle de vie : tickets, actifs, cookies, expirés et cookies orphelins ;
- réimpression filtrée par recherche et profil avec prix, devise et validité ;
- suppression des tickets expirés renforcée : cookie + session active + scheduler avant suppression.

## PPP
- usage des profils : secrets et actifs ;
- audit de santé des secrets sans révéler les mots de passe ;
- détection des noms dupliqués, mots de passe apparemment absents et service `any`.

## Rapports
- résumé des ventes par profil avec nombre de ventes et chiffre d’affaires dans la devise globale.

## Limites
- audit statique uniquement dans cet environnement ; aucun `flutter analyze` ni test sur routeur réel n’est revendiqué.
- les rapprochements historiques signalent des écarts mais ne suppriment/réécrivent aucune donnée automatiquement.
