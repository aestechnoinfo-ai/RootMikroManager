# PPP / PPPoE avancé

Ce lot structure PPP comme un module autonome :
- hub PPP ;
- secrets et profils ;
- sessions actives ;
- monitoring configurable ;
- détails des sessions ;
- serveurs PPPoE ;
- interfaces PPP dynamiques ;
- export CSV.

Les profils PPP ne reçoivent pas de faux bouton enable/disable : ce comportement
est réservé aux ressources RouterOS qui exposent réellement `disabled`.

Le monitoring actif s'arrête en arrière-plan et reprend au retour.
L'export CSV n'ajoute pas `file_picker`.
