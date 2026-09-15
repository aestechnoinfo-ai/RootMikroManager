# Bridge & VLAN avancés

Ajoute Bridge Ports, éditeur PVID/frame-types/ingress-filtering, Bridge VLAN Table CRUD,
Bridge Hosts/FDB, Interface Lists et audit de sécurité VLAN.

Règles de sécurité appliquées :
- VLAN ID/PVID 1..4094 ;
- avertissement avant configuration pouvant couper le management ;
- distinction tagged/untagged et port CPU (bridge) ;
- entrées dynamiques VLAN non éditées ;
- audit simple du chemin de management ;
- pas d'activation automatique de vlan-filtering.
