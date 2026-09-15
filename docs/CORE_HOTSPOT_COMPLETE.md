# RootMikroManager — Core + Hotspot

Cette étape renforce la construction fonctionnelle, sans travail APK.

## Cœur corrigé
- SQLite version 3 avec migration de `created_at`.
- Repository routeurs corrigé et modification d'un routeur ajoutée.
- Commandes RouterOS sérialisées pour éviter le mélange des réponses.
- Identity/Resource lisent réellement les lignes `!re`.
- Ping et traceroute corrigés.
- Décodage RouterOS 5 octets ajouté.
- Gestion `!trap` / `!fatal` renforcée.

## Hotspot
Le module est désormais séparé en :
- Utilisateurs ;
- Profils ;
- Utilisateurs actifs ;
- Cookies ;
- Hosts ;
- IP Binding.

Les profils Hotspot et les vouchers restent volontairement séparés pour éviter leur confusion.
