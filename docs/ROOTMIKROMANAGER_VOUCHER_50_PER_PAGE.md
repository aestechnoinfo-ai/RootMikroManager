# Vouchers RootMikroManager — éditeur avancé

L'éditeur permet d'activer ou désactiver individuellement :
- titre ;
- nom du Hotspot ;
- mot de passe ;
- profil ;
- validité ;
- limite de temps ;
- limite de données ;
- prix ;
- URL Login ;
- QR Code ;
- numéro du ticket ;
- commentaire.

Le code voucher est obligatoire et ne peut pas être masqué. Sa typographie
est volontairement plus grande et plus grasse que toutes les autres données.

## Densité d'impression

Le réglage `Tickets par page` accepte de 1 à 50. L'impression PDF découpe le
lot en pages exactes selon cette valeur et adapte automatiquement la grille :
1–2, 3–6, 7–12, 13–20, 21–30, 31–40 et 41–50 tickets par page.

À très forte densité (40–50/page), les éléments secondaires sont réduits et
le QR est masqué dans le PDF si nécessaire pour préserver la lisibilité du
code voucher. Le code reste toujours prioritaire.

## Modèles

- Default
- QR
- Small / Thermal

L'URL QR utilise `username` et `password` lorsqu'une URL Login est configurée.
