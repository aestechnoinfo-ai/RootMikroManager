# WiFi — éditeurs, provisioning et sécurité ACL

Lot de consolidation WiFi :
- CRUD Configuration, Channel, Security et Datapath modernes ;
- secrets WiFi traités en écriture uniquement ;
- validation VLAN 1–4094 ;
- gestion CRUD des règles de provisioning CAPsMAN ;
- avertissement sur l’ordre des règles de provisioning ;
- validation MAC, signal-range et VLAN des Access Lists ;
- confirmation pour `query-radius` ;
- audit des rejets généraux susceptibles de masquer les règles suivantes ;
- avertissement VLAN/Bridge pour certains pilotes qcom-ac ;
- familles WiFi moderne et Wireless legacy conservées séparément.

Aucun secret WiFi existant n'est volontairement relu ou réaffiché.
