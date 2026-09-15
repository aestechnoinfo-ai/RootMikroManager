# RootMikroManager — API-SSL & Hotspot/Vouchers Advanced

## RouterOS API-SSL
Le client RouterOS accepte maintenant un transport `SecureSocket`.

- port 8728 : Socket TCP ;
- port 8729 : SecureSocket TLS.

Pour les réseaux privés MikroTik, les certificats auto-signés sont fréquents.
La couche actuelle autorise donc temporairement ces certificats sur 8729.
Une phase de durcissement permettra de choisir :
- validation stricte ;
- certificat auto-signé autorisé ;
- empreinte/certificat épinglé.

## Hotspot avancé
Le service RouterOS possède maintenant les primitives pour :
- déconnecter un utilisateur actif ;
- créer une IP Binding ;
- convertir un Host en Binding.

## Vouchers avancés
Le générateur prend maintenant en charge :
- quantité 1–500 ;
- profil Hotspot réel ;
- préfixe ;
- longueur username ;
- longueur password ;
- mode lettres/chiffres/alphanumérique ;
- password = username ;
- limit-uptime ;
- limit-bytes-total ;
- commentaire ;
- progression ;
- historique SQLite ;
- audit de génération.

Les vouchers restent des utilisateurs Hotspot générés. Ils ne sont jamais
confondus avec les profils Hotspot.
