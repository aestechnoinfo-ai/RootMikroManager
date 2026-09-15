# Ajout utilisateur Hotspot

RootMikroManager possède maintenant un écran distinct pour l'ajout manuel d'un utilisateur Hotspot.

Champs :
- Server ;
- Username ;
- Password ;
- Profile ;
- Time Limit ;
- Data Limit en MB ou GB ;
- Commentaire ;
- état activé/désactivé.

Le commentaire transmis à RouterOS reçoit automatiquement :
- `vc-` quand username = password ;
- `up-` quand username != password.

Cette création manuelle reste séparée du générateur de vouchers par lots. Un compte Hotspot ordinaire n'est donc pas assimilé à un ticket restant sur le Dashboard.
