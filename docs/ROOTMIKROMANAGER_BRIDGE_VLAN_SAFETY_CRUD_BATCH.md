# Bridge & VLAN — sécurité et CRUD

Ce lot ajoute :
- CRUD des Interface Lists personnalisées ;
- CRUD des membres statiques de listes ;
- protection de all/none/dynamic/static ;
- éditeur VLAN avec sélection tagged/untagged ;
- prise en compte RouterOS 7.17+ pour les Interface Lists dans Bridge VLAN ;
- suppression confirmée des VLANs statiques, protection des dynamiques ;
- éditeur Bridge Port avancé (PVID, frame-types, ingress-filtering et STP) ;
- audit du port CPU/bridge, PVID, trunks, access ports et chevauchements tagged/untagged ;
- écran de compatibilité RouterOS ;
- vraie entrée visible « Bridge & VLAN avancés » dans le hub Interfaces.

RootMikroManager n’active pas automatiquement `vlan-filtering=yes`.
