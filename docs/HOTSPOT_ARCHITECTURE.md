# Architecture des interfaces Hotspot

RootMikroManager sépare volontairement deux usages qui manipulent les mêmes
objets RouterOS.

## Hotspot / R.M.M

Interface métier inspirée de Mikhmon : utilisateurs, profils commerciaux,
vouchers, ventes et expiration. Sa route historique `hotspot` est conservée.

## Administration / RootBox — Hotspot (WinBox)

Interface technique inspirée de `IP > Hotspot` dans WinBox :

- Hotspot Setup et résumé ;
- Servers et Server Profiles ;
- IP Pools ;
- Users et User Profiles ;
- Active, Hosts, Cookies et IP Bindings.

Le hub utilise une route distincte (`hotspot-winbox`). Cette séparation évite
qu'une évolution commerciale modifie la navigation d'administration RouterOS.
