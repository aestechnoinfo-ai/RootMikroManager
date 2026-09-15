# RootMikroManager - Voucher QR / TLS / Restore

## API-SSL 8729 corrigé
Le transport est réellement sélectionné dans `RouterOsClient` :

- 8728 -> `Socket.connect`
- 8729 -> `SecureSocket.connect`

L'écran de connexion permet de choisir :
- certificat auto-signé autorisé ;
- validation TLS stricte.

Le mode auto-signé est utile sur de nombreux réseaux MikroTik privés.
Pour une exposition Internet, la validation stricte reste préférable.

## Vouchers QR et impression
Les vouchers générés peuvent maintenant être :
- prévisualisés dans une grille responsive ;
- affichés avec QR Code ;
- imprimés via le dialogue système ;
- exportés en PDF via le pipeline `printing` + `pdf`.

Le QR encode explicitement les identifiants du voucher et son profil.
Il ne transforme jamais un profil Hotspot en voucher.

Versions choisies pour rester compatibles avec le SDK large du projet :
- `pdf: ^3.12.0`
- `printing: ^5.14.3`
- `qr_flutter: ^4.1.0`

## Restauration RouterOS
Pour un fichier `.backup` déjà présent dans `/file`, RootMikroManager peut
envoyer `/system/backup/load`.

Sécurité UI :
- confirmation explicite ;
- mot de passe facultatif du backup ;
- l'utilisateur doit taper `RESTAURER` ;
- avertissement qu'une restauration remplace la configuration et redémarre.

Le transfert binaire téléphone <-> routeur reste une fonction distincte.
