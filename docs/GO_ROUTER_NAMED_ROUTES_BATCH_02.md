# go_router — routes nommées finales, lot 02

## Domaines durcis

Cette passe migre vers des routes nommées les écrans centraux suivants :

- Hotspot Users ;
- Hotspot Advanced ;
- Hotspot Active ;
- Voucher Generator ;
- PPP Active ;
- PPP Management.

## Payloads typés

`navigation_payloads.dart` centralise les données complexes nécessaires à la
navigation sans les placer dans l'URL :

- utilisateur Hotspot ;
- ligne optionnelle d'édition ;
- profil initial d'ajout Hotspot ;
- Host Hotspot ;
- lot d'impression voucher ;
- résultat de génération voucher ;
- session PPP active.

Les mots de passe contenus dans certaines données métier ne sont jamais
sérialisés dans le chemin ou la query string : ils restent en mémoire via
`GoRouterState.extra`.

## Routes ajoutées

- `/hotspot/users/edit`
- `/hotspot/users/add`
- `/hotspot/users/export`
- `/hotspot/ip-binding/edit`
- `/hotspot/hosts/detail`
- `/hotspot/monitor/settings`
- `/vouchers/print`
- `/vouchers/generation-result`
- `/ppp/monitor/settings`
- `/ppp/active/detail`
- `/ppp/secrets/edit`
- `/ppp/profiles/edit`

## Progression

Pont générique avant la passe : 109 appels.
Pont générique après la passe : 94 appels.

`MaterialPageRoute` reste à zéro.
