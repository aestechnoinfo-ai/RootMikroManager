# Hotspot Users - parité RootMikroManager officiel

Sources étudiées :
- `hotspot/users.php`
- `hotspot/userbyname.php`
- `process/resethotspotuser.php`
- `process/removeexpiredhotspotuser.php`
- `process/removehotspotuserbycomment.php`

## Liste
- tous les users ;
- filtre profil ;
- filtre commentaire/lot ;
- recherche nom, serveur, profil, MAC, commentaire ;
- filtre Expired (`limit-uptime=1s`) ;
- enable / disable ;
- suppression ;
- impression Default / QR ;
- accès à l'éditeur complet.

## Éditeur
- Enabled
- Server
- Username
- Password + show/hide
- Profile
- MAC Address (lecture)
- Uptime (lecture)
- Bytes In / Out (lecture)
- Time Limit
- Data Limit MB / GB
- Comment

Le profil associé fournit aussi :
Validity, Price, Selling Price et Lock User.

## Reset RootMikroManager
Reproduit `resethotspotuser.php` :
1. `limit-uptime=0`
2. `comment=""`
3. `/ip/hotspot/user/reset-counters`
4. suppression du scheduler portant le nom du user.

## Suppression des expirés
Cible les users `limit-uptime=1s`.

## Suppression par lot
RootMikroManager officiel filtre simultanément :
- `comment=<commentaire>`
- `uptime=00:00:00`

RootMikroManager conserve cette protection afin de ne supprimer que les
vouchers du lot encore inutilisés.
