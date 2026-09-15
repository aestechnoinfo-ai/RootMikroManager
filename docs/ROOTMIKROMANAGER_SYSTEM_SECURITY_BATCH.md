# Administration & sécurité RouterOS

Ce lot ajoute un hub dédié à l'administration système :
- résumé sécurité ;
- identité du routeur ;
- horloge et fuseau ;
- utilisateurs RouterOS ;
- groupes ;
- services IP ;
- certificats.

## Services IP
Les services existants de RouterOS sont modifiables mais aucun nouveau service
n'est créé. RootMikroManager permet de modifier le port, les adresses autorisées,
le nombre maximal de sessions, le certificat et l'état activé/désactivé.

## Horloge
Date, heure, fuseau et détection automatique du fuseau sont configurables.

## Certificats
Inventaire, common-name, expiration, fingerprint et état trusted.
La génération/signature/import/export de certificats reste une phase distincte.
