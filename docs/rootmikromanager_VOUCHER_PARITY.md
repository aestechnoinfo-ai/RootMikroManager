# RootMikroManager - Parité génération vouchers RootMikroManager

Référence étudiée : dépôt officiel `laksa19/rootmikromanagerv3`, notamment
`hotspot/generateuser.php`, `hotspot/adduser.php` et les templates `voucher/`.

## Options reproduites

- Quantity : 1 à 560 ;
- Server : `all` + `/ip/hotspot/print` ;
- User Mode :
  - `up` = Username & Password ;
  - `vc` = Username = Password ;
- User Length : 3 à 8 ;
- Prefix : maximum 6 caractères ;
- Suffix : maximum 6 caractères, extension RootMikroManager ;
- concaténation stricte `prefix + code + suffix`, sans tiret ni séparateur automatique ;
- Character : lower, upper, upplow, mix, mix1, mix2, num ;
- Profile : profils existants sur le MikroTik ;
- Time Limit ;
- Data Limit en MB ou GB ;
- commentaire additionnel ;
- commentaire structuré compatible `up-...` / `vc-...` ;
- création réelle dans `/ip/hotspot/user` ;
- `server`, `profile`, `limit-uptime`, `limit-bytes-total` ;
- Print Default ;
- Print QR ;
- Print Small.

## Métadonnées du profil

Comme RootMikroManager officiel, RootMikroManager lit le préfixe `:put(...)` du
`on-login` du profil pour retrouver :

- validity ;
- price ;
- selling price ;
- lock user.

Ces valeurs sont affichées avant génération et transmises au rendu voucher.

## Amélioration RootMikroManager

Avant chaque création, les noms déjà présents dans `/ip/hotspot/user` sont
connus localement. Une nouvelle combinaison est tentée jusqu'à 50 fois pour
éviter une collision de username lors des générations en lot.

## Séparation stricte

Un **profil Hotspot** n'est jamais traité comme un voucher.
Le voucher est un `/ip/hotspot/user` associé à un profil existant.

## Extension Suffix RootMikroManager

Le suffixe est facultatif et n'existe pas dans le formulaire RootMikroManager officiel.
RootMikroManager l'ajoute sans modifier le code généré :

`username = prefix + generatedCode + suffix`

Aucun tiret, espace ou autre séparateur n'est ajouté automatiquement.
Si l'administrateur souhaite un tiret, il doit le saisir lui-même dans le préfixe ou le suffixe.
En mode `vc`, le résultat complet devient à la fois le username et le password.
En mode `up`, le suffixe ne modifie que le username ; le mot de passe numérique reste indépendant comme dans RootMikroManager.

## Character mode

La branche PHP officielle `up` ne traite pas `num`; l'option est masquée par le JavaScript de RootMikroManager.
RootMikroManager reproduit ce comportement explicitement : `num` est disponible uniquement en mode `vc`.
Lors d'un passage de `vc/num` vers `up`, le mode repasse automatiquement à `lower`.
