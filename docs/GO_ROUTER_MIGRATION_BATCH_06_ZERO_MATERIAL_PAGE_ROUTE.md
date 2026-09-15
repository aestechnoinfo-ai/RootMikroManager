# go_router — lot de migration 06

## Résultat principal

Les 31 derniers fichiers utilisant `MaterialPageRoute` ont été migrés.

État après cette passe :
- `MaterialPageRoute` dans `lib/` : 0
- fichiers concernés : 0
- appels au pont `PreparedAppRouter.pushPage` : 135

La migration de la navigation impérative vers la coque `go_router` est donc
terminée au niveau des `MaterialPageRoute`.

## Important

Le projet utilise encore volontairement le pont temporaire
`PreparedAppRouter.pushPage<T>()`. Ce pont permet à `go_router` de porter les
écrans existants et leurs retours typés pendant que les routes finales sont
déclarées domaine par domaine.

La prochaine étape n'est plus de supprimer `MaterialPageRoute`, mais de
remplacer progressivement le pont générique par de vraies routes nommées :
- Hotspot ;
- Vouchers ;
- PPP ;
- Reports ;
- Network ;
- Firewall ;
- VPN ;
- System ;
- Tools / Backup / Settings.

## Règle

Aucun nouvel écran ne doit réintroduire `MaterialPageRoute`. Toute nouvelle
navigation doit utiliser une route nommée `go_router` ou, temporairement,
`PreparedAppRouter.pushPage<T>()` pendant la phase de consolidation.
