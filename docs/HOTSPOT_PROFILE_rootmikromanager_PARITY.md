# Hotspot Profile - parité RootMikroManager

Cette phase reprend le formulaire `adduserprofile.php` fourni comme référence.

## Champs pris en charge
- Name
- Address Pool
- Shared Users
- Rate Limit [up/down]
- Expired Mode : None / Remove / Notice / Remove & Record / Notice & Record
- Validity
- Grace Period
- Price
- Selling Price
- Lock User
- Parent Queue

## Données dynamiques
- Address Pool : `/ip/pool/print`
- Parent Queue : `/queue/simple/print ?dynamic=false`

## Création / modification
Le profil est envoyé vers `/ip/hotspot/user/profile/add` ou `set` avec :
`name`, `address-pool`, `rate-limit`, `shared-users`,
`status-autorefresh=1m`, `on-login` et `parent-queue`.

## Expiration
Les modes autres que None créent ou mettent à jour un scheduler de
surveillance portant le nom du profil. En cas de renommage, le scheduler de
l'ancien nom est réutilisé et renommé. Les doublons éventuels sont supprimés.

## Grace Period
Le formulaire PHP fourni lit `graceperiod`, mais cette version ne l'utilise
pas dans `$onlogin` ni `$bgservice`. RootMikroManager conserve donc le champ
pour compatibilité d'interface sans inventer un comportement absent de la
source fournie.

## Lock User
Le mode Lock User ajoute au `on-login` une commande qui associe le voucher à
l'adresse MAC utilisée lors de la première connexion.
