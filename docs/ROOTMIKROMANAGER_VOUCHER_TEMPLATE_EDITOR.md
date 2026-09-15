# Éditeur de vouchers RootMikroManager

L'éditeur natif propose :
- modèle Default ;
- modèle QR ;
- modèle Small / Thermal ;
- aperçu ;
- remise à zéro ;
- titre ;
- nom du Hotspot ;
- devise ;
- URL de connexion QR ;
- affichage optionnel du profil, de la validité et du prix.

Les réglages sont enregistrés dans SQLite (`app_settings`).

Quand une URL de connexion est renseignée, le QR contient une URL de type :
`<loginUrl>?username=<user>&password=<password>`.

Sinon, RootMikroManager utilise son payload QR interne.

La présentation Flutter/PDF remplace l'ancien principe de modification
directe de templates PHP/HTML.
